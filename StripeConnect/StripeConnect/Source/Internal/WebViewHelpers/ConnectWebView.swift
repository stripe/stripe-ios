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

// MARK: - Private

private extension ConnectWebView {
    // Opens the given navigation in a PopupWebViewController
    func openInPopup(configuration: WKWebViewConfiguration,
                     navigationAction: WKNavigationAction) -> WKWebView? {
        guard let presentPopup else {
            assertionFailure("Cannot present popup")
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

    // Opens the given URL in an SFSafariViewController
    func openInAppSafari(url: URL) {
        guard let presentPopup else {
            assertionFailure("Cannot present popup")
            return
        }

        let safariVC = SFSafariViewController(url: url)
        safariVC.dismissButtonStyle = .done
        safariVC.modalPresentationStyle = .popover
        // TODO: Do we want to update tint colors to match appearance?
        presentPopup(safariVC)
    }

    // Opens with UIApplication.open, if supported
    func openOnSystem(url: URL) {
        guard UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
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

        if let url = navigationAction.request.url {
            // Only `http` or `https` URL schemes can be opened in WKWebView or
            // SFSafariViewController. Opening other schemes, like `mailto`, will
            // cause a fatal error.
            guard Set(["http", "https"]).contains(url.scheme) else {
                openOnSystem(url: url)
                return nil
            }

            // Only open popups to known hosts inside PopupWebViewController,
            // otherwise use an SFSafariViewController
            guard let host = url.host,
                    StripeConnectConstants.allowedHosts.contains(host) else {
                openInAppSafari(url: url)
                return nil
            }
        }

        return openInPopup(configuration: configuration, navigationAction: navigationAction)
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

    // MARK: Downloads
    // https://developer.apple.com/videos/play/wwdc2021/10032/?time=1050

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        // Allow JS initiated downloads
        navigationAction.shouldPerformDownload ? .download : .allow
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse
    ) async -> WKNavigationResponsePolicy {
        // Allow server initiated downloads
        if navigationResponse.canShowMIMEType,
           let response = navigationResponse.response as? HTTPURLResponse,
           let contentType = response.value(forHTTPHeaderField: "Content-Type"),
           contentType.range(of: "attachment", options: .caseInsensitive) != nil {
            return .download
        }

        return .allow
    }

    func webView(_ webView: WKWebView,
                 navigationAction: WKNavigationAction,
                 didBecome download: WKDownload) {
        // Set download delegate for JS initiated downloads
        // TODO
    }

    func webView(_ webView: WKWebView,
                 navigationResponse: WKNavigationResponse,
                 didBecome download: WKDownload) {
        // Set download for server initiated downloads
        // TODO
    }
}
