//
//  ConnectWebViewController.swift
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

    /// The current version for the SDK
    let sdkVersion: String?

    init(configuration: WKWebViewConfiguration,
         // Only override for tests
         urlOpener: ApplicationURLOpener = UIApplication.shared,
         fileManager: FileManager = .default,
         sdkVersion: String? = StripeAPIConfiguration.STPSDKVersion) {
        self.urlOpener = urlOpener
        self.fileManager = fileManager
        self.sdkVersion = sdkVersion
        configuration.applicationNameForUserAgent = "- stripe-ios/\(sdkVersion ?? "")"
        webView = .init(frame: .zero, configuration: configuration)
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

    override func loadView() {
        view = webView
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        // Default disable swipe to dismiss
        parent?.isModalInPresentation = true
    }
}

// MARK: - Private

@available(iOS 15, *)
private extension ConnectWebViewController {
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

        present(navController, animated: true)
        return popupVC.webView
    }

    // Opens the given URL in an SFSafariViewController
    func openInAppSafari(url: URL) {
        let safariVC = SFSafariViewController(url: url)
        safariVC.dismissButtonStyle = .done
        safariVC.modalPresentationStyle = .popover
        present(safariVC, animated: true)
    }

    // Opens with UIApplication.open, if supported
    func openOnSystem(url: URL) {
        urlOpener.openIfPossible(url)
    }

    func showErrorAlert(for error: Error?) {
        // TODO: MXMOBILE-2491 Log analytic when receiving an error
        debugPrint(String(describing: error))

        let alert = UIAlertController(
            title: nil,
            message: NSError.stp_unexpectedErrorMessage(),
            preferredStyle: .alert)
        present(alert, animated: true)
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
        // Override from subclass
    }
}

// MARK: - WKNavigationDelegate

@available(iOS 15, *)
extension ConnectWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        // Override from subclass
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
extension ConnectWebViewController {
    // This extension is an abstraction layer to implement `WKDownloadDelegate`
    // functionality and make it testable. There's no way to instantiate
    // `WKDownload` in tests without causing an EXC_BAD_ACCESS error.

    func download(decideDestinationUsing response: URLResponse,
                  suggestedFilename: String) async -> URL? {
        if downloadedFile != nil {
            // If there's already a downloaded file, it means there were multiple
            // simultaneous downloads or we didn't clean up the URL correctly
            // TODO: MXMOBILE-2491 Log error analytic
            debugPrint("Multiple downloads")
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
        guard let downloadedFile,
              fileManager.fileExists(atPath: downloadedFile.path) else {
            // `downloadedFile` should never be nil here
            // If file doesn't exist, it indicates something went wrong creating
            // the temp file or the system deleted the temp file too quickly
            // TODO: MXMOBILE-2491 Log error analytic
            showErrorAlert(for: nil)
            cleanupDownloadedFile()
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [downloadedFile], applicationActivities: nil)
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
