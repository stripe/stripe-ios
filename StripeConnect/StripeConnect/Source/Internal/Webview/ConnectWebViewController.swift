//
//  ConnectWebViewController.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/3/24.
//

import Foundation
import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import WebKit

enum ConnectWebViewControllerError: Int, Error {
    case downloadFileDoesNotExist
    case multipleDownloads
}

/**
 Custom implementation of a web view that handles:
 - Camera access
 - Popup windows
 - Opening email links
 - Downloads 
 */
@available(iOS 15, *)
class ConnectWebViewController: UIViewController {

    let webView: WKWebView

    /// File URL for a downloaded file
    var downloadedFile: URL?

    /// The instance that will handle opening external urls
    let urlOpener: ApplicationURLOpener

    /// The file manager responsible for creating temporary file directories to store downloads
    let fileManager: FileManager

    /// The analytics client used to log load errors
    let analyticsClient: ComponentAnalyticsClient

    /// The current version for the SDK
    let sdkVersion: String?

    /// Popups with an allowed host will open in a PopupViewController and all others will open in a SafariVC.
    /// Camera permission requests from allowed hosts use the app's camera permissions while all other requests will explicitly ask for user permission.
    let allowedHosts: [String]

    init(configuration: WKWebViewConfiguration,
         analyticsClient: ComponentAnalyticsClient,
         allowedHosts: [String],
         // Only override for tests
         urlOpener: ApplicationURLOpener = UIApplication.shared,
         fileManager: FileManager = .default,
         sdkVersion: String? = StripeAPIConfiguration.STPSDKVersion) {
        self.analyticsClient = analyticsClient
        self.urlOpener = urlOpener
        self.fileManager = fileManager
        self.sdkVersion = sdkVersion
        configuration.applicationNameForUserAgent = "- stripe-ios/\(sdkVersion ?? "")"
        webView = .init(frame: .zero, configuration: configuration)
        webView.allowsLinkPreview = false

        self.allowedHosts = allowedHosts
        super.init(nibName: nil, bundle: nil)

        // Allow the web view to be inspected for debug builds on 16.4+
        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif

        webView.uiDelegate = self
        webView.navigationDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func loadView() {
        view = webView
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        // Default disable swipe to dismiss
        parent?.isModalInPresentation = true
    }

    // MARK: - Internal

    func showAlertAndLog(error: Error,
                         file: StaticString = #file,
                         line: UInt = #line) {
        analyticsClient.logClientError(error, file: file, line: line)

        let alert = UIAlertController(
            title: nil,
            message: NSError.stp_unexpectedErrorMessage(),
            preferredStyle: .alert)
        present(alert, animated: true)
    }

    func webViewDidFinishNavigation(to url: URL?) {
        // Override from subclass
    }

    func webViewDidFailNavigation(withError error: any Error) {
        // Override from subclass
    }

    func reload() {
        self.webView.reload()
    }

    /*
     Note: The default behavior if this is not implemented is reloading the webview.
     If you do implement webViewWebContentProcessDidTerminate like below then you have to
     manually call reload. This is implemented explicitly to prevent this pitfall in the future
     and also to allow for overrides.

     To test this functionality you can follow this guide:
     https://gist.github.com/jasonbekolay/dad7c446ae1b02f174dc3eb3a5ea70ee
     */
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        self.reload()
    }

    struct Alert: Codable, Equatable {
        struct Buttons: Codable, Equatable {
            let ok: String?
            let cancel: String?
        }
        let title: String?
        let message: String?
        var buttons: Buttons?
    }

    func presentAlert(_ alert: Alert, okAction: (() -> Void)? = nil, cancelAction: (() -> Void)? = nil) {
        let alertController = UIAlertController(
            title: alert.title,
            message: alert.message,
            preferredStyle: .alert
        )

        if let okButtonTitle = alert.buttons?.ok {
            alertController.addAction(UIAlertAction(title: okButtonTitle, style: .default) { _ in
                okAction?()
            })
        }

        if let cancelButtonTitle = alert.buttons?.cancel {
            alertController.addAction(UIAlertAction(title: cancelButtonTitle, style: .cancel) { _ in
                cancelAction?()
            })
        }

        self.present(alertController, animated: true)
    }
}

// MARK: - Private

@available(iOS 15, *)
private extension ConnectWebViewController {
    // Opens the given navigation in a PopupWebViewController
    func openInPopup(configuration: WKWebViewConfiguration,
                     navigationAction: WKNavigationAction) -> WKWebView? {
        let popupVC = PopupWebViewController(configuration: configuration,
                                             analyticsClient: analyticsClient,
                                             navigationAction: navigationAction,
                                             allowedHosts: allowedHosts,
                                             urlOpener: urlOpener,
                                             sdkVersion: sdkVersion)
        let navController = UINavigationController(rootViewController: popupVC)
        popupVC.navigationItem.rightBarButtonItem = .init(systemItem: .done, primaryAction: .init(handler: { [weak popupVC] _ in
            popupVC?.dismiss(animated: true)
        }))

        present(navController, animated: true)
        return popupVC.webView
    }

    // Opens the given URL in an SFSafariViewController
    func openInAppSafari(url: URL) {
        let safariVC = SFSafariViewController(url: url)
        safariVC.dismissButtonStyle = .done
        safariVC.modalPresentationStyle = .pageSheet
        present(safariVC, animated: true)
    }

    // Opens with UIApplication.open, if supported
    func openOnSystem(url: URL) {
        do {
            try urlOpener.openIfPossible(url)
        } catch {
            analyticsClient.logClientError(error)
        }
    }

    func cleanupDownloadedFile() {
        guard let downloadedFile else { return }

        // Delete file since we don't need it anymore
        DispatchQueue.global(qos: .background).async { [weak self] in
            try? self?.fileManager.removeItem(at: downloadedFile)
            // Note: no need to handle failures since:
            // - It's best-effort to clean up the file
            // - Expected in cases where there was an error creating the temp file
        }

        // Remove reference so we can log if we inadvertently get simultaneous downloads
        self.downloadedFile = nil
    }

    /// Checks if the given URL is a data export URL from Stripe's S3 bucket
    func isDataExportURL(_ url: URL) -> Bool {
        guard let host = url.host else { return false }
        return host.contains("stripe-data-exports") ||
               (host.contains("s3.amazonaws.com") && url.path.contains("stripe-data-exports"))
    }

    /// Checks if the given host is an S3 domain
    func isS3Host(_ host: String) -> Bool {
        return host.contains("s3.amazonaws.com") || host.contains("stripe-data-exports")
    }
}

// MARK: - WKUIDelegate

@available(iOS 15, *)
extension ConnectWebViewController: WKUIDelegate {
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

            // Special handling for data export URLs - these should be treated as downloads
            // rather than popups to prevent frame load interruptions
            if isDataExportURL(url) {
                // For data export URLs, return nil to let the navigation proceed normally
                // The download will be handled by the navigation response delegate
                return nil
            }

            // Only open popups to known hosts inside PopupWebViewController,
            // otherwise use an SFSafariViewController
            guard let host = url.host,
                    allowedHosts.contains(host) else {
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
        // But exclude S3 domains which are only used for downloads
        // https://developer.apple.com/videos/play/wwdc2021/10032/?time=754
        if allowedHosts.contains(origin.host) && !isS3Host(origin.host) {
            return .grant
        } else {
            return .deny
        }
    }

    func webViewDidClose(_ webView: WKWebView) {
        // Override from subclass
    }
}

// MARK: - WKNavigationDelegate

@available(iOS 15, *)
extension ConnectWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        /*
         The web view does not adjust its safe area insets after it finishes loading.
         This causes a race condition where the horizontal safe area insets are
         rendered incorrectly in landscape with Face ID devices if the page finishes
         loading before the view is laid out.

         The fix is to force the web view to redraw after the page finishes loading:
         https://stackoverflow.com/a/59452941/4133371
         */
        webView.setNeedsLayout()
        webViewDidFinishNavigation(to: webView.url)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        webViewDidFailNavigation(withError: error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        webViewDidFailNavigation(withError: error)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        /*
         `shouldPerformDownload` will be true if the request has MIME types
         or a `Content-Type` header indicating it's a download or it originated
         as a JS download.

         NOTE: We sometimes can't know if a request should be a download until
         after its response is received. Those cases are handled by
         `decidePolicyFor navigationResponse` below.
         */

        // Check if this is a data export URL, which should be treated as a download
        if let url = navigationAction.request.url, isDataExportURL(url) {
            return .download
        }

        return navigationAction.shouldPerformDownload ? .download : .allow
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

        return .allow
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo) async {
        presentAlert(.from(message: message, isConfirmationAlert: false))
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping @MainActor (Bool) -> Void) {
        presentAlert(.from(message: message, isConfirmationAlert: true), okAction: {
            completionHandler(true)
        }, cancelAction: {
            completionHandler(false)
        })
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
extension ConnectWebViewController {
    // This extension is an abstraction layer to implement `WKDownloadDelegate`
    // functionality and make it testable. There's no way to instantiate
    // `WKDownload` in tests without causing an EXC_BAD_ACCESS error.

    func download(decideDestinationUsing response: URLResponse,
                  suggestedFilename: String) async -> URL? {
        if downloadedFile != nil {
            analyticsClient.logClientError(ConnectWebViewControllerError.multipleDownloads)
        }

        // The temporary filename must be unique or the download will fail.
        // To ensure uniqueness, append a UUID to the directory path in case a
        // file with the same name was already downloaded from this app.
        let tempDir = fileManager
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        do {
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        } catch {
            showAlertAndLog(error: error)
            return nil
        }

        downloadedFile = tempDir.appendingPathComponent(suggestedFilename)
        return downloadedFile
    }

    func download(didFailWithError error: any Error,
                  resumeData: Data?) {
        showAlertAndLog(error: error)
    }

    func downloadDidFinish() {
        guard let downloadedFile,
              fileManager.fileExists(atPath: downloadedFile.path) else {
            // `downloadedFile` should never be nil here
            // If file doesn't exist, it indicates something went wrong creating
            // the temp file or the system deleted the temp file too quickly
            showAlertAndLog(error: ConnectWebViewControllerError.downloadFileDoesNotExist)
            cleanupDownloadedFile()
            return
        }

        // Since downloads can happen async and we don't know where in the webView
        // the download action was triggered, a popover presentation (default on iPad)
        // won't look good. Instead, use a `formSheet` presentation style.
        let activityViewController = FormSheetActivityViewController(activityItems: [downloadedFile], applicationActivities: nil)
        activityViewController.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.cleanupDownloadedFile()
        }
        present(activityViewController, animated: true)
    }
}

// MARK: - WKDownloadDelegate

@available(iOS 15, *)
extension ConnectWebViewController: WKDownloadDelegate {
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

@available(iOS 15, *)
extension ConnectWebViewController.Alert {
    static func from(message: String, isConfirmationAlert: Bool) -> ConnectWebViewController.Alert {
        var alert = decodeAlert(from: message) ?? .init(title: nil, message: message, buttons: nil)
        let okText = alert.buttons?.ok ?? String.Localized.ok
        let cancelText = alert.buttons?.cancel ?? String.Localized.cancel
        alert.buttons = .init(ok: okText, cancel: isConfirmationAlert ? cancelText : alert.buttons?.cancel)
        return alert
    }

    private static func decodeAlert(from jsonString: String) -> ConnectWebViewController.Alert? {
        guard let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(ConnectWebViewController.Alert.self, from: jsonData)
    }
}
