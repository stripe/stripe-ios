//
//  PopupWebViewController.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/1/24.
//

import UIKit
import WebKit

/// Presented when a new target is opened from `ComponentWebView`
class PopupWebViewController: UIViewController, WKUIDelegate {
    let webView: WKWebView

    private var titleObserver: NSKeyValueObservation?

    init(configuration: WKWebViewConfiguration,
         navigationAction: WKNavigationAction) {
        webView = .init(frame: .zero, configuration: configuration)
        webView.load(navigationAction.request)
        super.init(nibName: nil, bundle: nil)

        webView.uiDelegate = self

        // Keep navbar title in sync with web view
        titleObserver = webView.observe(\.title) { [weak self] webView, _ in
            self?.title = webView.title
        }
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

    // MARK: - WKUIDelegate

    func webViewDidClose(_ webView: WKWebView) {
        dismiss(animated: true)
    }
}
