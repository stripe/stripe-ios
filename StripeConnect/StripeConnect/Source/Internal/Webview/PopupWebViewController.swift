//
//  PopupWebViewController.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/1/24.
//

@_spi(STP) import StripeCore
import UIKit
import WebKit

/// Presented when a new target is opened from `StripeConnectWebView`
@available(iOS 15, *)
class PopupWebViewController: ConnectWebViewController {

    private var titleObserver: NSKeyValueObservation?

    init(configuration: WKWebViewConfiguration,
         analyticsClient: ComponentAnalyticsClient,
         navigationAction: WKNavigationAction,
         allowedHosts: [String],
         urlOpener: ApplicationURLOpener = UIApplication.shared,
         sdkVersion: String? = StripeAPIConfiguration.STPSDKVersion) {
        super.init(configuration: configuration,
                   analyticsClient: analyticsClient,
                   allowedHosts: allowedHosts,
                   urlOpener: urlOpener,
                   sdkVersion: sdkVersion)
        webView.load(navigationAction.request)

        // Keep navbar title in sync with web view
        titleObserver = webView.observe(\.title) { [weak self] webView, _ in
            self?.title = webView.title
        }

        // Add "Done" button to dismiss the view
        navigationItem.rightBarButtonItem = .init(systemItem: .done, primaryAction: .init(handler: { [weak self] _ in
            self?.dismiss(animated: true)
        }))
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

    override func webViewDidClose(_ webView: WKWebView) {
        super.webViewDidClose(webView)
        dismiss(animated: true)
    }
}
