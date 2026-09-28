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
