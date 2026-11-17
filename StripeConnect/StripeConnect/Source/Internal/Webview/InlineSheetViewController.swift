//
//  InlineSheetViewController.swift
//  StripeConnect
//

import UIKit
import WebKit

/// Shows a window that an inline component's Connect.js opened for one of its dialogs in a native sheet.
/// Connect.js draws the dialog into the window from the component's web view, so the window has no bridge of
/// its own, and it can't leave its first document.
final class InlineSheetViewController: UIViewController {
    static let minimumHeight: CGFloat = 120

    private static let detentIdentifier = UISheetPresentationController.Detent.Identifier("stripe-connect-inline-sheet")

    let sheetId: String
    let webView: WKWebView

    /// The window's first document, an accessory layer page on the Connect.js origin
    let documentURL: URL

    /// The content height from Connect.js, in points
    private(set) var contentHeight: CGFloat = 0

    var sheetBackgroundColor: UIColor {
        didSet {
            viewIfLoaded?.backgroundColor = sheetBackgroundColor
        }
    }

    /// The sheet went away while it was shown, from a swipe, a tap outside it, or its presenter going away
    var didDismiss: ((InlineSheetViewController) -> Void)?

    /// Connect.js closed the window
    var didCloseWindow: ((InlineSheetViewController) -> Void)?

    /// Opens a window the sheet's document asked for the way the component opens links
    var openWindow: ((WKWebViewConfiguration, WKNavigationAction) -> WKWebView?)?

    init(configuration: WKWebViewConfiguration,
         sheetId: String,
         documentURL: URL,
         backgroundColor: UIColor) {
        self.sheetId = sheetId
        self.documentURL = documentURL
        self.sheetBackgroundColor = backgroundColor
        // WebKit requires the web view for a window to use the configuration it passes in.
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .pageSheet
        webView.allowsLinkPreview = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.bounces = false
        // The sheet already sits below the status bar, so safe-area insets would only push the content down.
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = self
        webView.uiDelegate = self

        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let containerView = UIView()
        containerView.backgroundColor = sheetBackgroundColor
        webView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: containerView.topAnchor),
            webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
        ])
        view = containerView
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Also covers the screen behind the sheet going away, which dismisses it without asking its presentation controller.
        if isBeingDismissed || presentingViewController == nil {
            didDismiss?(self)
        }
    }

    /// Sizes the sheet to its content before each presentation
    func prepareForPresentation() {
        presentationController?.delegate = self
        guard let sheet = sheetPresentationController else { return }
        sheet.prefersGrabberVisible = true
        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        if #available(iOS 16.0, *) {
            sheet.detents = [
                .custom(identifier: Self.detentIdentifier) { [weak self] context in
                    min(max(self?.contentHeight ?? 0, Self.minimumHeight), context.maximumDetentValue)
                },
            ]
            sheet.selectedDetentIdentifier = Self.detentIdentifier
        } else {
            sheet.detents = [.medium()]
            sheet.selectedDetentIdentifier = .medium
        }
    }

    func updateContentHeight(_ height: CGFloat) {
        guard height != contentHeight else { return }
        contentHeight = height
        guard presentingViewController != nil,
              let sheet = sheetPresentationController else {
            return
        }
        if #available(iOS 16.0, *) {
            sheet.animateChanges {
                sheet.invalidateDetents()
            }
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension InlineSheetViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        didDismiss?(self)
    }
}

// MARK: - WKNavigationDelegate

extension InlineSheetViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        // Frames inside the dialog, like embedded Stripe forms, load as usual.
        if let targetFrame = navigationAction.targetFrame, !targetFrame.isMainFrame {
            return .allow
        }
        if let url = navigationAction.request.url, isSameDocument(url) {
            return .allow
        }
        return .cancel
    }

    private func isSameDocument(_ url: URL) -> Bool {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var documentComponents = URLComponents(url: documentURL, resolvingAgainstBaseURL: false)
        components?.fragment = nil
        documentComponents?.fragment = nil
        return components != nil && components == documentComponents
    }
}

// MARK: - WKUIDelegate

extension InlineSheetViewController: WKUIDelegate {
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        openWindow?(configuration, navigationAction)
    }

    func webViewDidClose(_ webView: WKWebView) {
        didCloseWindow?(self)
    }
}
