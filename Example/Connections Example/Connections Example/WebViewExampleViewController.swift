//
//  WebViewExampleViewController.swift
//  Connections Example
//
//  Created by Vardges Avetisyan on 3/14/22.
//

import UIKit
import WebKit

class WebViewExampleController: UIViewController, WKNavigationDelegate {

    private let webAppURL = URL(string: "https://pacific-florentine-dosa.glitch.me/checkout")!

    // MARK: - View Properties

    @objc
    private(set) lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero)
        webView.uiDelegate = self
        webView.navigationDelegate = self

        return webView
    }()

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(webView)
        webView.load(URLRequest(url: webAppURL))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        webView.frame = view.bounds
    }
}


// MARK: - WKUIDelegate

extension WebViewExampleController: WKUIDelegate {

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // A link is attempting to open in a new window
        // Open it in the platform's default browser
        if navigationAction.targetFrame?.isMainFrame != true,
           let url = navigationAction.request.url {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        return nil
    }
}
