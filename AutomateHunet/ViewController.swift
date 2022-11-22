//
//  ViewController.swift
//  AutomateHunet
//
//  Created by Jinwoo Kim on 11/22/22.
//

import Cocoa
import WebKit

@MainActor
final class ViewController: NSViewController {
    @IBOutlet weak var webView: WKWebView!
    private var speedUpTask: Task<Void, Never>?
    
    deinit {
        speedUpTask?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url: URL = .init(string: "https://365h.hunet.co.kr/Home")!
        let request: URLRequest = .init(url: url)
        webView.load(request)
        
        speedUpTask = .detached(priority: .low) { [webView] in
            while !Task.isCancelled {
                await withCheckedContinuation { continuation in
                    Task { @MainActor in
                        webView?.evaluateJavaScript("document.getElementById('main').contentWindow.document.querySelector('video').playbackRate = 2.0;") { _, _ in
                            continuation.resume(returning: ())
                        }
                    }
                }
                
                await withCheckedContinuation { continuation in
                    Task { @MainActor in
                        webView?.evaluateJavaScript("document.querySelector('video').playbackRate = 2.0;") { _, _ in
                            continuation.resume(returning: ())
                        }
                    }
                }
                
                try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
            }
        }
    }
}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        webView.load(navigationAction.request)
        return nil
    }
}

extension ViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo) async -> Bool {
        guard message != "다음 차시를 학습하시겠습니까?" else {
            return true
        }
        
        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                let alert: NSAlert = .init()
                alert.messageText = message
                alert.addButton(withTitle: "취소")
                alert.addButton(withTitle: "확인")
                
                alert.beginSheetModal(for: webView.window!) { response in
                    switch response {
                    case .alertFirstButtonReturn:
                        continuation.resume(returning: false)
                    case .alertSecondButtonReturn:
                        continuation.resume(returning: true)
                    default:
                        fatalError()
                    }
                }
            }
        }
    }
}
