//
//  ConnectWebView.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/3/24.
//

import SafariServices
@_spi(STP) import StripeCore
import WebKit

/**
 Custom implementation of a web view that handles:
 - Camera access
 - Popup windows
 - Opening email links
 - Downloads  TODO MXMOBILE-2485
 */
@available(iOS 15, *)
class ConnectWebView: WKWebView {

    /// A dictionary tracking download destinations
    /// - key: The download request URL
    /// - value: The local file URL it was downloaded to
    private var downloadDestinations: [URL: URL] = [:]

    private var optionalPresentPopup: ((UIViewController) -> Void)?

    /// Closure to present a popup web view controller.
    /// This is required for any components that can open a popup, otherwise an assertionFailure will occur.
    var presentPopup: (UIViewController) -> Void {
        get {
            assert(optionalPresentPopup != nil, "Cannot present popup")
            // TODO: MXMOBILE-2491 Log as analytics when pop up is not set.
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

@available(iOS 15, *)
private extension ConnectWebView {
    // Opens the given navigation in a PopupWebViewController
    func openInPopupWebViewController(configuration: WKWebViewConfiguration,
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

    func shouldNavigate(toURL url: URL) -> Bool {
        // Only open popups to known hosts inside PopupWebViewController,
        // otherwise use an SFSafariViewController

        ["http", "https"].contains(url.scheme)
        && url.host.map(StripeConnectConstants.allowedHosts.contains) != false
    }

    /// Returns true if URL is handled externally
    func openInSystemOrSafari(_ url: URL) {
        // Only `http` or `https` URL schemes can be opened in WKWebView or
        // SFSafariViewController. Opening other schemes, like `mailto`, will
        // cause a fatal error.
        if !["http", "https"].contains(url.scheme) {
            openOnSystem(url: url)
        } else {
            openInAppSafari(url: url)
        }
    }

    func showErrorAlert(for error: Error) {
        // TODO: Log error
        debugPrint(error)

        let alert = UIAlertController(
            title: nil,
            message: NSError.stp_unexpectedErrorMessage(),
            preferredStyle: .alert)
        presentPopup(alert)
    }
}

// MARK: - WKUIDelegate

@available(iOS 15, *)
extension ConnectWebView: WKUIDelegate {
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        // If targetFrame is nil, this is a popup
        guard navigationAction.targetFrame == nil else { return nil }

        if let url = navigationAction.request.url,
           !shouldNavigate(toURL: url) {
            openInSystemOrSafari(url)
        }

        return openInPopupWebViewController(configuration: configuration,
                                            navigationAction: navigationAction)
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

@available(iOS 15, *)
extension ConnectWebView: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        navigationAction.shouldPerformDownload ? .download : .allow
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse
    ) async -> WKNavigationResponsePolicy {
        // Response is not an HTML response
        if let mimeType = navigationResponse.response.mimeType,
           !mimeType.lowercased().split(separator: "/").contains("html") {
            return .download
        }

        // Not an HTTP request
        guard let response = navigationResponse.response as? HTTPURLResponse else {
            return .allow
        }

        // Attachment content type
        if navigationResponse.canShowMIMEType,
           let contentType = response.value(forHTTPHeaderField: "Content-Type"),
           contentType.range(of: "attachment", options: .caseInsensitive) != nil {
            return .download
        }

        // Response is from an unrecognized host, don't open in an embedded web view
        if let url = response.url,
           !shouldNavigate(toURL: url) {
            openInSystemOrSafari(url)
            return .cancel
        }

        return .allow
    }

    func webView(_ webView: WKWebView,
                 navigationAction: WKNavigationAction,
                 didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView,
                 navigationResponse: WKNavigationResponse,
                 didBecome download: WKDownload) {
        download.delegate = self
    }
}

// MARK: - WKDownloadDelegate

extension ConnectWebView: WKDownloadDelegate {
    func download(_ download: WKDownload,
                  decideDestinationUsing response: URLResponse,
                  suggestedFilename: String) async -> URL? {
        guard let requestUrl = download.originalRequest?.url else {
            // TODO: MXMOBILE-2491 log error
            return nil
        }

        // Create uniquely named directory in case a file by the same name has already been
        // downloaded from this app
        let tempDir = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        } catch {
            showErrorAlert(for: error)
            return nil
        }

        let tempUrl = tempDir.appendingPathComponent(suggestedFilename)
        downloadDestinations[requestUrl] = tempUrl
        return tempUrl
    }

    func download(_ download: WKDownload,
                  didFailWithError error: any Error,
                  resumeData: Data?) {
        showErrorAlert(for: error)
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let requestUrl = download.originalRequest?.url,
              let tempUrl = downloadDestinations[requestUrl] else {
            // TODO: MXMOBILE-2491 log error
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [tempUrl], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self
        presentPopup(activityViewController)

        // Cleanup download URL
        downloadDestinations.removeValue(forKey: requestUrl)
    }
}
