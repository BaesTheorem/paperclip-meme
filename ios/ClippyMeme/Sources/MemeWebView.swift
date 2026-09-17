import SwiftUI
import WebKit
import UniformTypeIdentifiers

/// Hosts the generator page from the bundled web/ folder.
///
/// The page is served through a custom `clippy://` scheme rather than loaded
/// as a file URL: `fetch()` and canvas export are both refused on file://
/// origins, and the PNG export needs both. The scheme handler reads straight
/// out of the bundle, so nothing listens on a port.
struct MemeWebView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(BundleSchemeHandler(), forURLScheme: "clippy")
        config.userContentController.add(context.coordinator, name: "savePng")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        webView.isOpaque = false
        webView.backgroundColor = .white
        context.coordinator.webView = webView
        webView.load(URLRequest(url: URL(string: "clippy://app/index.html")!))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    /// Receives the exported PNG from the page and hands it to the share
    /// sheet, which is where Save Image, AirDrop and Messages live.
    final class Coordinator: NSObject, WKScriptMessageHandler {
        weak var webView: WKWebView?

        func userContentController(_ controller: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard message.name == "savePng",
                  let body = message.body as? [String: Any],
                  let dataUrl = body["dataUrl"] as? String,
                  let comma = dataUrl.firstIndex(of: ","),
                  let data = Data(base64Encoded: String(dataUrl[dataUrl.index(after: comma)...]))
            else { return }

            let name = (body["name"] as? String) ?? "clippy.png"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
            do { try data.write(to: url, options: .atomic) } catch { return }

            let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            guard let webView, let root = webView.window?.rootViewController else { return }
            if let pop = sheet.popoverPresentationController {
                pop.sourceView = webView
                pop.sourceRect = CGRect(x: webView.bounds.midX, y: webView.bounds.maxY - 1, width: 1, height: 1)
            }
            root.present(sheet, animated: true)
        }
    }
}

/// Serves `clippy://app/<path>` from the bundle's web/ folder.
final class BundleSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else { return }
        var path = url.path
        if path.isEmpty || path == "/" { path = "/index.html" }
        let fileURL = Bundle.main.bundleURL.appendingPathComponent("web" + path)

        guard let data = try? Data(contentsOf: fileURL) else {
            task.didReceive(HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil)!)
            task.didFinish()
            return
        }
        let ext = fileURL.pathExtension
        let mime = UTType(filenameExtension: ext)?.preferredMIMEType ?? "application/octet-stream"
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1",
                                       headerFields: ["Content-Type": mime,
                                                      "Content-Length": String(data.count),
                                                      "Access-Control-Allow-Origin": "*"])!
        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}
