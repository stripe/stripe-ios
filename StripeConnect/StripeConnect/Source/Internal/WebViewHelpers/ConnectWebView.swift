//
//  ConnectWebView.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/3/24.
//

import SafariServices
import WebKit

/**
 Custom implementation of a web view that handles:
 - Camera access
 - Popup windows
 - Downloads (TODO)
 - Opening email links (TODO)
 */
class ConnectWebView: WKWebView {

    /// Closure to present a popup web view controller.
    /// This is required for any components that can open a popup, otherwise an assertionFailure will occur.
    var presentPopup: ((UIViewController) -> Void)?

    /// Closure that executes when the view finishes loading.
    /// - Note: If any JS needs to be evaluated immediately after instantiation, do that here.
    var didFinishLoading: ((ConnectWebView) -> Void)?

    /// Closure that executes when `window.close()` is called in JS
    var didClose: ((ConnectWebView) -> Void)?

    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)

        // Allow the web view to be inspected for debug builds on 16.4+
        #if DEBUG
        if #available(iOS 16.4, *) {
            isInspectable = true
        }
        #endif

        uiDelegate = self
        navigationDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - WKUIDelegate

extension ConnectWebView: WKUIDelegate {
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        // If targetFrame is nil, this is a popup
        guard navigationAction.targetFrame == nil else { return nil }

        guard let presentPopup else {
            assertionFailure("Cannot present popup")
            return nil
        }

        // Only open popups to known hosts inside PopupWebViewController,
        // otherwise use an SFSafariViewController
        if let url = navigationAction.request.url,
           url.host == nil || !StripeConnectConstants.allowedHosts.contains(url.host!) {
            let safariVC = SFSafariViewController(url: url)
            safariVC.dismissButtonStyle = .done
            safariVC.modalPresentationStyle = .popover
            // TODO: Do we want to update tint colors to match appearance?
            presentPopup(safariVC)
            return nil
        }

        let popupVC = PopupWebViewController(configuration: configuration, navigationAction: navigationAction)
        let navController = UINavigationController(rootViewController: popupVC)
        popupVC.navigationItem.rightBarButtonItem = .init(systemItem: .done, primaryAction: .init(handler: { [weak popupVC] _ in
            popupVC?.dismiss(animated: true)
        }))

        presentPopup(navController)
        return popupVC.webView
    }

    func webView(_ webView: WKWebView,
                 decideMediaCapturePermissionsFor origin: WKSecurityOrigin,
                 initiatedBy frame: WKFrameInfo,
                 type: WKMediaCaptureType) async -> WKPermissionDecision {
        // Don't prompt the user for camera permissions from a Connect host
        // https://developer.apple.com/videos/play/wwdc2021/10032/?time=754
        StripeConnectConstants.allowedHosts.contains(origin.host) ? .grant : .deny
    }

    func webViewDidClose(_ webView: WKWebView) {
        // Call our custom handler when `window.close()` is called from JS
        self.didClose?(self)
    }
}

// MARK: - WKNavigationDelegate

extension ConnectWebView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Call our custom handler when we know the page has finished loading
        didFinishLoading?(self)
    }

    // TODO: Downloads
    // https://developer.apple.com/videos/play/wwdc2021/10032/?time=1050

}
