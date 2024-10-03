//
//  ConnectWebView.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/3/24.
//

import QuickLook
import SafariServices
@_spi(STP) import StripeCore
import WebKit

/**
 Custom implementation of a web view that handles:
 - Camera access
 - Popup windows
 - Opening email links
 - Downloads 
 */
@available(iOS 15, *)
class ConnectWebView: WKWebView {

    /// File URL for a downloaded file
    var downloadedFile: URL?

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

    /// The file manager responsible for creating temporary file directories
    let fileManager: FileManager

    /// The current version for the SDK
    let sdkVersion: String?

    init(frame: CGRect,
         configuration: WKWebViewConfiguration,
         // Only override for tests
         urlOpener: ApplicationURLOpener = UIApplication.shared,
         fileManager: FileManager = .default,
         sdkVersion: String? = StripeAPIConfiguration.STPSDKVersion) {
        self.urlOpener = urlOpener
        self.fileManager = fileManager
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
        // If targetFrame is non-nil, this is not a popup and will be handled in
        // the navigation delegate's `decidePolicyFor navigationResponse` method
        guard navigationAction.targetFrame == nil else { return nil }

        if let url = navigationAction.request.url,
           !shouldNavigate(toURL: url) {
            openInSystemOrSafari(url)
            return nil
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
        // `shouldPerformDownload` will be true if the request has MIME types
        // or a `Content-Type` header indicating it's a download or it originated
        // as a JS download.
        //
        // This is not entirely accurate and we can't know a request should be a
        // download until evaluating the response.

        navigationAction.shouldPerformDownload ? .download : .allow
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse
    ) async -> WKNavigationResponsePolicy {

        // Downloads will typically originate from a non-allow-listed host (e.g. S3)
        // so first check if the response is a download before evaluating the host

        // The response should be a download if its Content-Disposition is
        // shaped like `attachment; filename=payouts.csv`
        if navigationResponse.canShowMIMEType,
           let response = navigationResponse.response as? HTTPURLResponse,
           let contentDisposition = response.value(forHTTPHeaderField: "Content-Disposition"),
           contentDisposition
            .split(separator: ";")
            .map({ $0.trimmingCharacters(in: .whitespaces) })
            .caseInsensitiveContains("attachment") {
            return .download
        }

        // Response is from an unrecognized host, don't open in an embedded web view
        if let url = navigationResponse.response.url,
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

// MARK: - WKDownloadDelegate implementation

@available(iOS 15, *)
extension ConnectWebView {
    // This extension is an abstraction layer to implement `WKDownloadDelegate`
    // functionality and make it testable. There's no way to instantiate
    // `WKDownload` in tests without causing an EXC_BAD_ACCESS error.

    func download(decideDestinationUsing response: URLResponse,
                  suggestedFilename: String) async -> URL? {
        // The temporary filename must be unique or the download will fail.
        // To ensure uniqueness, append a UUID to the directory path in case a
        // file with the same name was already downloaded from this app.
        let tempDir = fileManager
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        do {
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        } catch {
            showErrorAlert(for: error)
            return nil
        }

        downloadedFile = tempDir.appendingPathComponent(suggestedFilename)
        return downloadedFile
    }

    func download(didFailWithError error: any Error,
                  resumeData: Data?) {
        showErrorAlert(for: error)
    }

    func downloadDidFinish() {

        // Display a preview of the file to the user
        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewController.modalPresentationStyle = .pageSheet
        presentPopup(previewController)
    }
}

// MARK: - WKDownloadDelegate

@available(iOS 15, *)
extension ConnectWebView: WKDownloadDelegate {
    func download(_ download: WKDownload,
                  decideDestinationUsing response: URLResponse,
                  suggestedFilename: String) async -> URL? {
        await self.download(decideDestinationUsing: response,
                            suggestedFilename: suggestedFilename)
    }

    func download(_ download: WKDownload,
                  didFailWithError error: any Error,
                  resumeData: Data?) {
        self.download(didFailWithError: error, resumeData: resumeData)
    }

    func downloadDidFinish(_ download: WKDownload) {
        self.downloadDidFinish()
    }
}

// MARK: - QLPreviewControllerDataSource

@available(iOS 15, *)
extension ConnectWebView: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        downloadedFile == nil ? 0 : 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> any QLPreviewItem {
        // Okay to force-unwrap since numberOfPreviewItems returns 0 when downloadFile is nil
        downloadedFile! as QLPreviewItem
    }
}
