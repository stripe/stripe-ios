//
//  InlineSheetCoordinator.swift
//  StripeConnect
//

import UIKit
import WebKit

/// Turns the windows an inline component's Connect.js opens into native sheets.
///
/// A window becomes a sheet only if the component's web view opened it from a frame on the Connect.js origin and
/// its URL is an accessory layer page on that origin. A sheet is shown only once Connect.js reports its height with
/// `sheetChanged`, and Connect.js hears `sheetClosed` whenever a shown sheet goes away. Connect.js decides when
/// windows close, so a window it never reports stays hidden until it closes or the component's document goes away.
final class InlineSheetCoordinator {
    fileprivate enum State {
        /// Laid out off screen so Connect.js can draw and measure its dialog, but not shown
        case pending
        /// Shown to the user
        case showing
        /// Dismissed by the user or the app. The window stays loaded in case its dialog stays open.
        case hidden
    }

    fileprivate final class Sheet {
        let controller: InlineSheetViewController
        var state: State = .pending

        init(controller: InlineSheetViewController) {
            self.controller = controller
        }
    }

    private weak var host: UIViewController?
    private weak var componentWebView: WKWebView?
    private let componentURL: URL
    private let sendSheetClosed: (String) -> Void
    private let openWindow: (WKWebViewConfiguration, WKNavigationAction) -> WKWebView?
    private var sheets: [String: Sheet] = [:]

    var backgroundColor: UIColor {
        didSet {
            sheets.values.forEach { $0.controller.sheetBackgroundColor = backgroundColor }
        }
    }

    init(host: UIViewController,
         componentWebView: WKWebView,
         componentURL: URL,
         backgroundColor: UIColor,
         sendSheetClosed: @escaping (String) -> Void,
         openWindow: @escaping (WKWebViewConfiguration, WKNavigationAction) -> WKWebView?) {
        self.host = host
        self.componentWebView = componentWebView
        self.componentURL = componentURL
        self.backgroundColor = backgroundColor
        self.sendSheetClosed = sendSheetClosed
        self.openWindow = openWindow
    }

    deinit {
        dismissAll()
    }

    /// The web view of the sheet with this id, if its window is open
    func sheetWebView(for sheetId: String) -> WKWebView? {
        sheets[sheetId]?.controller.webView
    }

    /// Returns a web view to show a window in as a sheet, or nil to refuse the window
    func openSheet(from webView: WKWebView,
                   configuration: WKWebViewConfiguration,
                   navigationAction: WKNavigationAction) -> WKWebView? {
        // Connect.js opens sheets from its UI layer frame, so the source doesn't have to be the main frame.
        let sourceOrigin = navigationAction.sourceFrame.securityOrigin
        guard webView === componentWebView,
              InlineContract.isOrigin(scheme: sourceOrigin.protocol,
                                      host: sourceOrigin.host,
                                      port: sourceOrigin.port,
                                      of: componentURL),
              let url = navigationAction.request.url,
              let sheetId = InlineContract.sheetId(fromWindowURL: url, componentURL: componentURL),
              sheets[sheetId] == nil else {
            return nil
        }

        let controller = InlineSheetViewController(
            configuration: configuration,
            sheetId: sheetId,
            documentURL: url,
            backgroundColor: backgroundColor
        )
        controller.didDismiss = { [weak self] in self?.sheetDidDismiss($0) }
        controller.didCloseWindow = { [weak self] in self?.windowDidClose($0) }
        controller.openWindow = openWindow
        sheets[sheetId] = Sheet(controller: controller)
        stage(controller)
        return controller.webView
    }

    /// Shows a sheet at `height` points, including one the user closed whose dialog stayed open
    func sheetDidChange(sheetId: String, height: CGFloat) {
        guard let sheet = sheets[sheetId] else { return }
        sheet.controller.updateContentHeight(height)
        if sheet.state != .showing {
            present(sheet)
        }
    }

    /// Dismisses and releases every sheet without telling Connect.js, for when the component's document goes away
    func dismissAll() {
        let closedSheets = Array(sheets.values)
        sheets.removeAll()
        let shownControllers = closedSheets.filter { $0.state == .showing }.map(\.controller)
        closedSheets.forEach(release)
        // Dismissing a sheet's presenter also dismisses the sheets stacked above it.
        for controller in shownControllers where !shownControllers.contains(where: { $0 === controller.presentingViewController }) {
            controller.presentingViewController?.dismiss(animated: true)
        }
    }

    static func topmostPresenter(from viewController: UIViewController) -> UIViewController {
        var presenter = viewController
        while let presented = presenter.presentedViewController, !presented.isBeingDismissed {
            presenter = presented
        }
        return presenter
    }
}

// MARK: - Private

private extension InlineSheetCoordinator {
    func stage(_ controller: InlineSheetViewController) {
        guard let window = host?.viewIfLoaded?.window else { return }
        // Lays the window out off screen at the width it'll be shown at, so Connect.js can draw and measure its dialog.
        controller.view.frame = CGRect(x: 0, y: window.bounds.maxY, width: window.bounds.width, height: window.bounds.height)
        controller.view.accessibilityElementsHidden = true
        controller.view.isUserInteractionEnabled = false
        window.addSubview(controller.view)
    }

    func unstage(_ controller: InlineSheetViewController) {
        guard controller.isViewLoaded else { return }
        controller.view.removeFromSuperview()
        controller.view.accessibilityElementsHidden = false
        controller.view.isUserInteractionEnabled = true
    }

    func present(_ sheet: Sheet) {
        guard let host else { return }
        if sheet.state == .pending {
            unstage(sheet.controller)
        }
        sheet.state = .showing
        sheet.controller.prepareForPresentation()
        Self.topmostPresenter(from: host).present(sheet.controller, animated: true)
    }

    func sheetDidDismiss(_ controller: InlineSheetViewController) {
        guard let sheet = sheets[controller.sheetId],
              sheet.controller === controller,
              sheet.state == .showing else {
            return
        }
        sheet.state = .hidden
        sendSheetClosed(controller.sheetId)
    }

    func windowDidClose(_ controller: InlineSheetViewController) {
        guard let sheet = sheets[controller.sheetId], sheet.controller === controller else { return }
        sheets[controller.sheetId] = nil
        let wasShowing = sheet.state == .showing
        release(sheet)
        guard wasShowing else { return }
        sendSheetClosed(controller.sheetId)
        // Dismissing from the presenter also dismisses any sheets stacked above this one.
        controller.presentingViewController?.dismiss(animated: true)
    }

    func release(_ sheet: Sheet) {
        if sheet.state == .pending {
            unstage(sheet.controller)
        }
        sheet.controller.didDismiss = nil
        sheet.controller.didCloseWindow = nil
        sheet.controller.openWindow = nil
        sheet.controller.webView.stopLoading()
    }
}
