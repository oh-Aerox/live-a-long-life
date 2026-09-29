import Flutter
import UIKit
import PDFKit
import Vision

// UIScene 生命周期（iOS 27 上不采用会在正常启动时被系统终止）。
// 场景由 Info.plist 里的 FlutterSceneDelegate 处理，插件注册移到
// didInitializeImplicitFlutterEngine（官方 UIScene 迁移指南）。
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MedicalTextChannel") {
      MedicalTextChannel.register(with: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "BonjourChannel") {
      BonjourChannel.register(with: registrar.messenger())
    }
  }
}

/// 本地文字提取（D-23）：PDF 文字层直取 + 扫描页渲染 + Vision OCR。
/// 与 macos/Runner/MainFlutterWindow.swift 中的实现保持一致（Flutter
/// 双端原生代码不共享，改一处要同步另一处）。
class MedicalTextChannel: NSObject {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "life.long/medical_text", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "pdfPageCount":
        guard let path = args["path"] as? String,
              let doc = PDFDocument(url: URL(fileURLWithPath: path)) else {
          result(FlutterError(code: "open_failed", message: "无法打开 PDF", details: nil))
          return
        }
        result(doc.pageCount)

      case "pdfPageText":
        guard let path = args["path"] as? String, let page = args["page"] as? Int,
              let doc = PDFDocument(url: URL(fileURLWithPath: path)),
              let p = doc.page(at: page) else {
          result(FlutterError(code: "open_failed", message: "无法打开 PDF 页", details: nil))
          return
        }
        result(p.string)

      case "renderPdfPage":
        guard let path = args["path"] as? String, let page = args["page"] as? Int,
              let outPath = args["outPath"] as? String else {
          result(FlutterError(code: "bad_args", message: "缺少参数", details: nil))
          return
        }
        DispatchQueue.global(qos: .userInitiated).async {
          guard let doc = PDFDocument(url: URL(fileURLWithPath: path)),
                let p = doc.page(at: page) else {
            DispatchQueue.main.async {
              result(FlutterError(code: "open_failed", message: "无法打开 PDF 页", details: nil))
            }
            return
          }
          let bounds = p.bounds(for: .mediaBox)
          // OCR 用途：最长边约 2200px，太小认不清、太大白费内存。
          let scale = min(2200 / max(bounds.width, bounds.height), 4)
          let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
          let image = p.thumbnail(of: size, for: .mediaBox)
          guard let data = image.pngData() else {
            DispatchQueue.main.async {
              result(FlutterError(code: "render_failed", message: "渲染 PNG 失败", details: nil))
            }
            return
          }
          do {
            try data.write(to: URL(fileURLWithPath: outPath))
            DispatchQueue.main.async { result(outPath) }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(code: "write_failed", message: "写文件失败：\(error)", details: nil))
            }
          }
        }

      case "ocrImage":
        guard let path = args["path"] as? String else {
          result(FlutterError(code: "bad_args", message: "缺少 path", details: nil))
          return
        }
        DispatchQueue.global(qos: .userInitiated).async {
          let request = VNRecognizeTextRequest()
          request.recognitionLevel = .accurate
          request.recognitionLanguages = ["zh-Hans", "en-US"]
          request.usesLanguageCorrection = true
          let handler = VNImageRequestHandler(url: URL(fileURLWithPath: path), options: [:])
          do {
            try handler.perform([request])
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(code: "ocr_failed", message: "OCR 失败：\(error)", details: nil))
            }
            return
          }
          // Vision 的归一化坐标原点在左下，转成左上原点。
          let lines: [[String: Any]] = (request.results ?? []).compactMap { obs in
            guard let cand = obs.topCandidates(1).first else { return nil }
            let b = obs.boundingBox
            return [
              "text": cand.string,
              "x": Double(b.origin.x),
              "y": Double(1 - b.origin.y - b.height),
              "w": Double(b.width),
              "h": Double(b.height),
            ]
          }
          DispatchQueue.main.async { result(lines) }
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

/// 局域网发现（V4-M5 mDNS）：Mac 广播同步服务，手机按 Mac 的设备 ID 找回
/// 当前地址（Mac 换 IP 后不用重新配对）。服务名 `llal-<设备 ID>`，类型
/// `_llal-sync._tcp`。只负责找地址；连上后仍走配对时建立的加密认证，
/// 冒名的广播连不上。与另一端（ios/macos）的实现保持一致。
class BonjourChannel: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
  static let serviceType = "_llal-sync._tcp."
  static let shared = BonjourChannel()

  private var published: NetService?
  private var browser: NetServiceBrowser?
  private var resolving: [NetService] = []
  private var pending: FlutterResult?
  private var wanted: String?
  private var timer: Timer?
  private var collected: [String] = []
  private var settleTimer: Timer?

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "life.long/bonjour", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in shared.handle(call, result) }
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "publish":
      guard let name = args["name"] as? String, let port = args["port"] as? Int else {
        result(FlutterError(code: "bad_args", message: "需要 name 和 port", details: nil))
        return
      }
      published?.stop()
      let service = NetService(
        domain: "local.", type: BonjourChannel.serviceType, name: name, port: Int32(port))
      service.delegate = self
      if let hosts = args["hosts"] as? String, !hosts.isEmpty {
        service.setTXTRecord(NetService.data(fromTXTRecord: ["ips": Data(hosts.utf8)]))
      }
      service.publish()
      published = service
      result(true)
    case "unpublish":
      published?.stop()
      published = nil
      result(true)
    case "resolve":
      guard let name = args["name"] as? String else {
        result(FlutterError(code: "bad_args", message: "需要 name", details: nil))
        return
      }
      let timeoutMs = args["timeoutMs"] as? Int ?? 5000
      finish(nil)  // 上一次没完成的查找直接结束
      pending = result
      wanted = name
      let b = NetServiceBrowser()
      b.delegate = self
      browser = b
      b.searchForServices(ofType: BonjourChannel.serviceType, inDomain: "local.")
      timer = Timer.scheduledTimer(
        withTimeInterval: Double(timeoutMs) / 1000, repeats: false
      ) { [weak self] _ in self?.finish(nil) }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func netServiceBrowser(
    _ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool
  ) {
    guard service.name == wanted else { return }
    service.delegate = self
    resolving.append(service)
    service.resolve(withTimeout: 5)
  }

  func netServiceDidPublish(_ sender: NetService) {
    NSLog("[bonjour] 已广播 %@", sender.name)
  }

  func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
    NSLog("[bonjour] 广播失败 %@", errorDict.description)
  }

  func netServiceBrowser(
    _ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]
  ) {
    NSLog("[bonjour] 查找失败 %@", errorDict.description)
    finish(nil)
  }

  /// 返回全部 IPv4 地址（逗号分隔的 host:port）：Mac 在每块网卡上各广播一份
  /// （Wi-Fi 的局域网地址、数据线直连的 169.254 链路本地地址），各份的解析
  /// 结果先后到达。收到第一份后再等 1 秒收齐，由 Dart 端排序、逐个试连。
  func netServiceDidResolveAddress(_ sender: NetService) {
    // Mac 在 TXT 里写了自己的局域网地址：哪条链路先解析到都能拿到。
    if let txt = sender.txtRecordData(),
      let ips = NetService.dictionary(fromTXTRecord: txt)["ips"],
      let list = String(data: ips, encoding: .utf8)
    {
      for ip in list.split(separator: ",") where !ip.isEmpty {
        let addr = "\(ip):\(sender.port)"
        if !collected.contains(addr) { collected.append(addr) }
      }
    }
    for ip in (sender.addresses ?? []).compactMap({ BonjourChannel.ipv4($0) }) {
      let addr = "\(ip):\(sender.port)"
      if !collected.contains(addr) { collected.append(addr) }
    }
    guard !collected.isEmpty, settleTimer == nil else { return }
    settleTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) {
      [weak self] _ in
      guard let self = self else { return }
      self.finish(self.collected.joined(separator: ","))
    }
  }

  /// 只取 IPv4：同步服务绑在 anyIPv4 上，IPv6 链路本地地址连不上。
  private static func ipv4(_ data: Data) -> String? {
    return data.withUnsafeBytes { raw -> String? in
      guard let base = raw.baseAddress, raw.count >= MemoryLayout<sockaddr_in>.size
      else { return nil }
      guard base.assumingMemoryBound(to: sockaddr.self).pointee.sa_family
        == sa_family_t(AF_INET)
      else { return nil }
      var addr = base.assumingMemoryBound(to: sockaddr_in.self).pointee.sin_addr
      var buf = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
      guard inet_ntop(AF_INET, &addr, &buf, socklen_t(INET_ADDRSTRLEN)) != nil
      else { return nil }
      return String(cString: buf)
    }
  }

  private func finish(_ value: String?) {
    timer?.invalidate()
    timer = nil
    settleTimer?.invalidate()
    settleTimer = nil
    // 总超时到了但已收到部分地址：把收到的交出去，不当成没找到。
    let result = value ?? (collected.isEmpty ? nil : collected.joined(separator: ","))
    collected.removeAll()
    browser?.stop()
    browser = nil
    resolving.forEach { $0.stop() }
    resolving.removeAll()
    wanted = nil
    if let p = pending {
      pending = nil
      p(result)
    }
  }
}
