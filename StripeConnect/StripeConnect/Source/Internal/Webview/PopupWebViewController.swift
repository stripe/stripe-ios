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
class PopupWebViewController: UIViewController {
    let webView: ConnectWebView

    private var titleObserver: NSKeyValueObservation?

    init(configuration: WKWebViewConfiguration,
         navigationAction: WKNavigationAction,
         urlOpener: ApplicationURLOpener = UIApplication.shared,
         sdkVersion: String? = StripeAPIConfiguration.STPSDKVersion) {
        webView = .init(frame: .zero,
                        configuration: configuration,
                        urlOpener: urlOpener,
                        sdkVersion: sdkVersion)
        webView.load(navigationAction.request)
        super.init(nibName: nil, bundle: nil)

        // Keep navbar title in sync with web view
        titleObserver = webView.observe(\.title) { [weak self] webView, _ in
            self?.title = webView.title
        }

        // Dismiss the view controller when `window.close()` is called from JS
        webView.didClose = { [weak self] _ in
            self?.dismiss(animated: true)
        }
        webView.presentPopup = { [weak self] vc in
            self?.present(vc, animated: true)
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
}
