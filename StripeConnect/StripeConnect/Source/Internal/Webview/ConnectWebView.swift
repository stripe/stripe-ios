//
//  ConnectWebView.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/3/24.
//

@_spi(STP) import StripeCore
import SafariServices
import WebKit

/**
 Custom implementation of a web view that handles:
 - Camera access
 - Popup windows
 - Opening email links
 - Downloads  TODO MXMOBILE-2485
 */
class ConnectWebView: WKWebView {

    
    private var optionalPresentPopup: ((UIViewController) -> Void)?

    /// Closure to present a popup web view controller.
    /// This is required for any components that can open a popup, otherwise an assertionFailure will occur.
    var presentPopup: (UIViewController) -> Void {
        get {
            assert(optionalPresentPopup != nil,  "Cannot present popup")
            //TODO: MXMOBILE-2491 Log as analytics when pop up is not set.
            return optionalPresentPopup ?? { _ in }
        }
        set {
            optionalPresentPopup = newValue
        }
    }

    /// Closure that executes when `window.close()` is called in JS
    var didClose: ((ConnectWebView) -> Void)?

    /// The instance that will handle opening external urls
    let urlOpener: ApplicationURLOpener
    
    /// The current version for the SDK
    let sdkVersion: String?
    
    init(frame: CGRect,
         configuration: WKWebViewConfiguration,
         // Only override for tests
         urlOpener: ApplicationURLOpener = UIApplication.shared,
         sdkVersion: String? = StripeAPIConfiguration.STPSDKVersion) {
        self.urlOpener = urlOpener
        self.sdkVersion = sdkVersion
        configuration.applicationNameForUserAgent = "- stripe-ios/\(sdkVersion ?? "")"
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
        let popupVC = PopupWebViewController(configuration: configuration, 
                                             navigationAction: navigationAction,
                                             urlOpener: urlOpener,
                                             sdkVersion: sdkVersion)
        let navController = UINavigationController(rootViewController: popupVC)
        popupVC.navigationItem.rightBarButtonItem = .init(systemItem: .done, primaryAction: .init(handler: { [weak popupVC] _ in
            popupVC?.dismiss(animated: true)
        }))

        presentPopup(navController)
        return popupVC.webView
    }

    // Opens the given URL in an SFSafariViewController
    func openInAppSafari(url: URL) {
        let safariVC = SFSafariViewController(url: url)
        safariVC.dismissButtonStyle = .done
        safariVC.modalPresentationStyle = .popover
        presentPopup(safariVC)
    }

    // Opens with UIApplication.open, if supported
    func openOnSystem(url: URL) {
        urlOpener.openIfPossible(url)
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
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        // TODO: MXMOBILE-2485 Handle downloads
        .allow
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse
    ) async -> WKNavigationResponsePolicy {
        // TODO: MXMOBILE-2485 Handle downloads
        .allow
    }

    func webView(_ webView: WKWebView,
                 navigationAction: WKNavigationAction,
                 didBecome download: WKDownload) {
        // TODO: MXMOBILE-2485 Handle downloads
    }

    func webView(_ webView: WKWebView,
                 navigationResponse: WKNavigationResponse,
                 didBecome download: WKDownload) {
        // TODO: MXMOBILE-2485 Handle downloads
    }
}
