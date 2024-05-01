//
//  PopupWebViewController.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/1/24.
//

import UIKit
import WebKit

class PopupWebViewController: UIViewController, WKUIDelegate {
    let webView: WKWebView

    init(configuration: WKWebViewConfiguration,
         navigationAction: WKNavigationAction) {
        webView = .init(frame: .zero, configuration: configuration)
        webView.load(navigationAction.request)
        super.init(nibName: nil, bundle: nil)

        // Keep navbar title in sync with web view
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)

        webView.uiDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.frame = view.frame
        view = webView
        title = webView.title
    }

    override func observeValue(forKeyPath keyPath: String?, 
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard keyPath == #keyPath(WKWebView.title) else { return }
        
        title = webView.title
    }

    // MARK: - WKUIDelegate

    func webViewDidClose(_ webView: WKWebView) {
        dismiss(animated: true)
    }
}
