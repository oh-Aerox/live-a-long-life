import Flutter
import UIKit
import PDFKit
import UniformTypeIdentifiers
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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CloudFolderChannel") {
      CloudFolderChannel.register(with: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "BackgroundTaskChannel") {
      BackgroundTaskChannel.register(with: registrar.messenger())
    }
  }
}

/// 后台时间：Dart 在做模型请求等一时半会儿做不完的事时申请，做完归还。
/// 按次给编号，几件事同时在做也互不影响；系统收回时间时自动归还。
class BackgroundTaskChannel: NSObject {
  // 还没归还的编号，防止系统收回后 Dart 再归还一次（重复归还系统会报警告）。
  // 方法调用和收回回调都在主线程，不用加锁。
  private static var active = Set<Int>()

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "life.long/background_task", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "begin":
        var id = UIBackgroundTaskIdentifier.invalid
        id = UIApplication.shared.beginBackgroundTask(
          withName: args["name"] as? String
        ) { end(id.rawValue) }
        if id == .invalid {
          result(nil)
        } else {
          active.insert(id.rawValue)
          result(id.rawValue)
        }
      case "end":
        if let raw = args["id"] as? Int { end(raw) }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func end(_ raw: Int) {
    guard active.remove(raw) != nil else { return }
    UIApplication.shared.endBackgroundTask(UIBackgroundTaskIdentifier(rawValue: raw))
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

/// 局域网发现（mDNS）：Mac 广播同步服务，手机按 Mac 的设备 ID 找回
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

/// iCloud 备份文件夹（D-51）。免费签名没有 iCloud 能力，用不了 iCloud 容器，
/// 只能让用户在系统文件选择器里选一个 iCloud 云盘里的文件夹：
/// - pick：选文件夹，返回书签（之后凭书签访问，不用再选）；
/// - open / close：解析书签并开始 / 结束安全访问，期间 Dart 可以直接列目录、读文件；
/// - download / put / move / delete：经 NSFileCoordinator 读写，未下载的文件
///   先下载，写入的文件交给 iCloud 上传；notUploaded：哪些还没传到 iCloud；
/// - beginBackground / endBackground：切到后台时多要一点时间写完备份。
class CloudFolderChannel: NSObject, UIDocumentPickerDelegate {
  static let shared = CloudFolderChannel()

  private var pending: FlutterResult?
  // 同一路径可能同时被打开多次（备份进行中又打开了医疗文件空间），按次配对释放。
  private var opened: [String: [URL]] = [:]
  private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
  private let queue = DispatchQueue(label: "cloud-folder", qos: .utility)

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "life.long/cloud_folder", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in shared.handle(call, result) }
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "pick":
      pick(result)
    case "open":
      guard let b64 = args["bookmark"] as? String, let data = Data(base64Encoded: b64) else {
        result(FlutterError(code: "bad_args", message: "需要 bookmark", details: nil))
        return
      }
      var stale = false
      do {
        let url = try URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale)
        guard url.startAccessingSecurityScopedResource() else {
          result(FlutterError(code: "denied", message: "没有访问权限", details: nil))
          return
        }
        opened[url.path, default: []].append(url)
        var reply: [String: Any] = ["path": url.path]
        if stale, let d = try? url.bookmarkData() { reply["bookmark"] = d.base64EncodedString() }
        result(reply)
      } catch {
        result(FlutterError(code: "resolve_failed", message: "\(error.localizedDescription)", details: nil))
      }
    case "close":
      if let path = args["path"] as? String, let url = opened[path]?.popLast() {
        url.stopAccessingSecurityScopedResource()
        if opened[path]?.isEmpty == true { opened.removeValue(forKey: path) }
      }
      result(nil)
    case "notUploaded":
      let paths = args["paths"] as? [String] ?? []
      queue.async {
        let pending = paths.filter { path in
          let values = try? URL(fileURLWithPath: path).resourceValues(
            forKeys: [.ubiquitousItemIsUploadedKey])
          return values?.ubiquitousItemIsUploaded != true
        }
        DispatchQueue.main.async { result(pending) }
      }
    case "download":
      let paths = args["paths"] as? [String] ?? []
      queue.async {
        var failed: [String] = []
        for path in paths {
          var err: NSError?
          var ok = false
          // 协调读取会等系统把未下载的文件下载下来。
          NSFileCoordinator().coordinate(
            readingItemAt: URL(fileURLWithPath: path), options: [], error: &err
          ) { url in ok = FileManager.default.fileExists(atPath: url.path) }
          if err != nil || !ok { failed.append(path) }
        }
        DispatchQueue.main.async { result(failed) }
      }
    case "put":
      guard let from = args["from"] as? String, let to = args["to"] as? String else {
        result(FlutterError(code: "bad_args", message: "需要 from 和 to", details: nil))
        return
      }
      coordinatedWrite(to, options: .forReplacing, result) { url in
        let fm = FileManager.default
        try fm.createDirectory(
          at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fm.fileExists(atPath: url.path) { try fm.removeItem(at: url) }
        try fm.copyItem(at: URL(fileURLWithPath: from), to: url)
      }
    case "move":
      guard let from = args["from"] as? String, let to = args["to"] as? String else {
        result(FlutterError(code: "bad_args", message: "需要 from 和 to", details: nil))
        return
      }
      queue.async {
        var err: NSError?
        var failure: Error?
        NSFileCoordinator().coordinate(
          writingItemAt: URL(fileURLWithPath: from), options: .forMoving,
          writingItemAt: URL(fileURLWithPath: to), options: .forReplacing, error: &err
        ) { src, dst in
          do {
            let fm = FileManager.default
            if fm.fileExists(atPath: dst.path) { try fm.removeItem(at: dst) }
            try fm.moveItem(at: src, to: dst)
          } catch { failure = error }
        }
        DispatchQueue.main.async {
          if let e = failure ?? err {
            result(FlutterError(code: "io_failed", message: e.localizedDescription, details: nil))
          } else {
            result(nil)
          }
        }
      }
    case "delete":
      guard let path = args["path"] as? String else {
        result(FlutterError(code: "bad_args", message: "需要 path", details: nil))
        return
      }
      coordinatedWrite(path, options: .forDeleting, result) { url in
        if FileManager.default.fileExists(atPath: url.path) {
          try FileManager.default.removeItem(at: url)
        }
      }
    case "beginBackground":
      if backgroundTask == .invalid {
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "cloud-backup") {
          [weak self] in self?.endBackground()
        }
      }
      result(nil)
    case "endBackground":
      endBackground()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func endBackground() {
    guard backgroundTask != .invalid else { return }
    UIApplication.shared.endBackgroundTask(backgroundTask)
    backgroundTask = .invalid
  }

  private func coordinatedWrite(
    _ path: String, options: NSFileCoordinator.WritingOptions,
    _ result: @escaping FlutterResult, _ body: @escaping (URL) throws -> Void
  ) {
    queue.async {
      var err: NSError?
      var failure: Error?
      NSFileCoordinator().coordinate(
        writingItemAt: URL(fileURLWithPath: path), options: options, error: &err
      ) { url in
        do { try body(url) } catch { failure = error }
      }
      DispatchQueue.main.async {
        if let e = failure ?? err {
          result(FlutterError(code: "io_failed", message: e.localizedDescription, details: nil))
        } else {
          result(nil)
        }
      }
    }
  }

  private func pick(_ result: @escaping FlutterResult) {
    guard pending == nil else {
      result(FlutterError(code: "busy", message: "已经在选择文件夹", details: nil))
      return
    }
    let scene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
    var top = scene?.windows.first { $0.isKeyWindow }?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    guard let host = top else {
      result(FlutterError(code: "no_window", message: "找不到窗口", details: nil))
      return
    }
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
    picker.delegate = self
    picker.allowsMultipleSelection = false
    pending = result
    host.present(picker, animated: true)
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]
  ) {
    guard let result = pending else { return }
    pending = nil
    guard let url = urls.first else {
      result(nil)
      return
    }
    let started = url.startAccessingSecurityScopedResource()
    defer { if started { url.stopAccessingSecurityScopedResource() } }
    do {
      let bookmark = try url.bookmarkData()
      let icloud =
        (try? url.resourceValues(forKeys: [.isUbiquitousItemKey]))?.isUbiquitousItem ?? false
      result([
        "bookmark": bookmark.base64EncodedString(),
        "name": url.lastPathComponent,
        "icloud": icloud,
      ])
    } catch {
      result(FlutterError(code: "bookmark_failed", message: error.localizedDescription, details: nil))
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pending?(nil)
    pending = nil
  }
}
