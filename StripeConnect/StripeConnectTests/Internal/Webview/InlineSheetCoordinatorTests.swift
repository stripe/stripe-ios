//
//  InlineSheetCoordinatorTests.swift
//  StripeConnectTests
//

import SafariServices
@testable import StripeConnect
import UIKit
import WebKit
import XCTest

@MainActor
final class InlineSheetCoordinatorTests: XCTestCase {
    private var window: UIWindow!
    private var controller: InlineSheetHostController!
    private var sheetClosedRecorder: SheetMessageRecorder!
    private var sheetCloseRequestedRecorder: SheetMessageRecorder!
    private var componentOrigin: WKSecurityOrigin!

    override func setUp() async throws {
        try await super.setUp()
        let componentManager = EmbeddedComponentManager(apiClient: .init(publishableKey: "test"), fetchClientSecret: { nil })
        controller = InlineSheetHostController(
            componentManager: componentManager,
            componentType: .notificationBanner,
            loadContent: false,
            analyticsClientFactory: MockComponentAnalyticsClient.init,
            didFailLoadWithError: { _ in }
        )
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = controller
        window.makeKeyAndVisible()

        try await controller.webView.loadTrustedDocumentPreservingDelegate()
        sheetClosedRecorder = try await SheetMessageRecorder.install(function: "sheetClosed", in: controller.webView)
        sheetCloseRequestedRecorder = try await SheetMessageRecorder.install(function: "sheetCloseRequested", in: controller.webView)
        componentOrigin = try await inlineSheetSecurityOrigin(for: StripeConnectConstants.connectJSBaseURL)
    }

    override func tearDown() async throws {
        window.isHidden = true
        window = nil
        controller = nil
        try await super.tearDown()
    }

    // MARK: - Creating sheets

    func testOpensSheetForAccessoryLayerWindowFromComponentChildFrame() {
        let sheetWebView = openSheet()

        XCTAssertNotNil(sheetWebView)
        XCTAssertTrue(controller.inlineSheets?.sheetWebView(for: "sheet-1") === sheetWebView)
    }

    func testOpensSheetForAccessoryLayerWindowFromComponentMainFrame() {
        XCTAssertNotNil(openSheet(isMainFrame: true))
    }

    func testRefusesSheetFromCrossOriginChildFrame() async throws {
        let foreignOrigin = try await inlineSheetSecurityOrigin(for: URL(string: "https://foreign.example/frame.html")!)

        XCTAssertNil(openSheet(sourceOrigin: foreignOrigin))
        assertNoSheetOrPresentation()
    }

    func testRefusesSheetFromLookalikeOriginFrame() async throws {
        let lookalikeOrigin = try await inlineSheetSecurityOrigin(for: URL(string: "https://connect-js.stripe.com.evil.example/frame.html")!)

        XCTAssertNil(openSheet(sourceOrigin: lookalikeOrigin))
        assertNoSheetOrPresentation()
    }

    func testRefusesSheetFromWrongPortFrame() async throws {
        let wrongPortOrigin = try await inlineSheetSecurityOrigin(for: URL(string: "https://connect-js.stripe.com:8443/frame.html")!)

        XCTAssertNil(openSheet(sourceOrigin: wrongPortOrigin))
        assertNoSheetOrPresentation()
    }

    func testRefusesSheetFromHTTPFrame() async throws {
        let httpOrigin = try await inlineSheetSecurityOrigin(for: URL(string: "http://connect-js.stripe.com/frame.html")!)

        XCTAssertNil(openSheet(sourceOrigin: httpOrigin))
        assertNoSheetOrPresentation()
    }

    func testRefusesSheetFromOpaqueOriginFrame() async throws {
        let opaqueOrigin = try await inlineSheetOpaqueSecurityOrigin()

        XCTAssertNil(openSheet(sourceOrigin: opaqueOrigin))
        assertNoSheetOrPresentation()
    }

    func testRefusesSheetOpenedByAnotherWebView() {
        let otherWebView = WKWebView(frame: .zero, configuration: controller.webView.configuration)

        XCTAssertNil(openSheet(from: otherWebView))
        assertNoSheetOrPresentation()
    }

    func testRefusesLookalikeHostWindowURL() {
        XCTAssertNil(openSheet(url: URL(string: "https://connect-js.stripe.com.evil.example/accessory_layer_abc.html#os_sheet=true&os_sheet_id=sheet-1")!))
        assertNoSheetOrPresentation()
    }

    func testRefusesWrongPortWindowURL() {
        XCTAssertNil(openSheet(url: URL(string: "https://connect-js.stripe.com:8443/accessory_layer_abc.html#os_sheet=true&os_sheet_id=sheet-1")!))
        assertNoSheetOrPresentation()
    }

    func testRefusesHTTPWindowURL() {
        XCTAssertNil(openSheet(url: URL(string: "http://connect-js.stripe.com/accessory_layer_abc.html#os_sheet=true&os_sheet_id=sheet-1")!))
        assertNoSheetOrPresentation()
    }

    func testRefusesWrongPathWindowURL() {
        XCTAssertNil(openSheet(url: URL(string: "https://connect-js.stripe.com/other.html#os_sheet=true&os_sheet_id=sheet-1")!))
        assertNoSheetOrPresentation()
    }

    func testRefusesFolderPathWindowURL() {
        XCTAssertNil(openSheet(url: URL(string: "https://connect-js.stripe.com/v1.0/accessory_layer_abc.html#os_sheet=true&os_sheet_id=sheet-1")!))
        assertNoSheetOrPresentation()
    }

    func testRefusesAboutBlankWindowURL() {
        XCTAssertNil(openSheet(url: URL(string: "about:blank#os_sheet=true&os_sheet_id=sheet-1")!))
        assertNoSheetOrPresentation()
    }

    func testRefusesDataWindowURL() {
        XCTAssertNil(openSheet(url: URL(string: "data:text/html,hello#os_sheet=true&os_sheet_id=sheet-1")!))
        assertNoSheetOrPresentation()
    }

    func testRefusesJavaScriptWindowURL() {
        XCTAssertNil(openSheet(url: URL(string: "javascript:alert(1)//#os_sheet=true&os_sheet_id=sheet-1")!))
        assertNoSheetOrPresentation()
    }

    func testRefusesWindowURLWithDuplicateParams() {
        XCTAssertNil(openSheet(url: URL(string: "https://connect-js.stripe.com/accessory_layer_abc.html#os_sheet=true&os_sheet_id=sheet-1&os_sheet_id=sheet-2")!))
        assertNoSheetOrPresentation()
    }

    func testRefusesWindowURLWithInvalidSheetId() {
        XCTAssertNil(openSheet(url: URL(string: "https://connect-js.stripe.com/accessory_layer_abc.html#os_sheet=true&os_sheet_id=__proto__")!))
        assertNoSheetOrPresentation()
    }

    func testRefusesSheetIdThatIsAlreadyOpen() {
        let firstSheetWebView = openSheet()

        XCTAssertNil(openSheet())
        XCTAssertTrue(controller.inlineSheets?.sheetWebView(for: "sheet-1") === firstSheetWebView)
    }

    func testWindowThatIsNotASheetKeepsPopupHandling() {
        let action = InlineSheetMockNavigationAction(
            url: URL(string: "https://connect.stripe.com/help")!,
            sourceFrame: InlineSheetMockFrameInfo(isMainFrame: false, securityOrigin: componentOrigin)
        )

        let popupWebView = controller.webView(controller.webView,
                                              createWebViewWith: controller.webView.configuration,
                                              for: action,
                                              windowFeatures: WKWindowFeatures())

        let popup = (controller.lastPresentedController as? UINavigationController)?.topViewController as? PopupWebViewController
        popup?.webView.stopLoading()
        XCTAssertNotNil(popup)
        XCTAssertTrue(popup?.webView === popupWebView)
    }

    func testCrossOriginChildFrameWindowOpenDoesNotCreateSheet() async throws {
        let observer = WindowOpenObserver()
        controller.webView.configuration.userContentController.add(observer, name: WindowOpenObserver.name)
        defer {
            controller.webView.configuration.userContentController.removeScriptMessageHandler(forName: WindowOpenObserver.name)
        }

        controller.webView.loadHTMLString("""
        <!doctype html>
        <iframe sandbox="allow-scripts allow-popups" srcdoc='<script>
        const sheetWindow = window.open("\(InlineSheetTestURLs.accessoryLayer.absoluteString.replacingOccurrences(of: "&", with: "&amp;"))", "sheet-1");
        window.webkit.messageHandlers.\(WindowOpenObserver.name).postMessage({ opened: sheetWindow !== null });
        </script>'></iframe>
        """, baseURL: StripeConnectConstants.connectJSBaseURL)

        let opened = try await observer.waitForResult()
        XCTAssertFalse(opened)
        assertNoSheetOrPresentation()
    }

    // MARK: - Presenting sheets

    func testDoesNotPresentSheetBeforeSheetChanged() async throws {
        openSheet()

        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(controller.presentedControllers.isEmpty)
    }

    func testFirstSheetChangedPresentsSheetAtItsHeight() async throws {
        let sheetWebView = openSheet()

        let sheet = try await sendSheetChangedAndWaitForPresentation(height: 300)

        XCTAssertEqual(sheet.sheetId, "sheet-1")
        XCTAssertEqual(sheet.contentHeight, 300)
        XCTAssertTrue(sheet.webView === sheetWebView)
    }

    func testSheetChangedHeightIsClamped() async throws {
        openSheet()

        let sheet = try await sendSheetChangedAndWaitForPresentation(height: 20_000)

        XCTAssertEqual(sheet.contentHeight, 10_000)
    }

    func testSheetChangedForUnknownSheetIsIgnored() async throws {
        openSheet()

        try await controller.webView.evaluateJavaScriptAndWait("""
        window.webkit.messageHandlers.sheetChanged.postMessage({ sheetId: "sheet-2", height: 300 });
        true;
        """)

        XCTAssertTrue(controller.presentedControllers.isEmpty)
    }

    func testSheetChangedWithNonNumericHeightIsIgnored() async throws {
        openSheet()

        try await controller.webView.evaluateJavaScriptAndWait("""
        window.webkit.messageHandlers.sheetChanged.postMessage({ sheetId: "sheet-1", height: "tall" });
        true;
        """)

        XCTAssertTrue(controller.presentedControllers.isEmpty)
    }

    func testLaterSheetChangedResizesPresentedSheet() async throws {
        openSheet()
        let sheet = try await sendSheetChangedAndWaitForPresentation(height: 300)

        try await sendSheetChanged(height: 420)

        XCTAssertEqual(sheet.contentHeight, 420)
        XCTAssertEqual(controller.presentedControllers.count, 1)
    }

    // MARK: - Closing sheets

    func testSwipeOrOutsideTapSendsSheetClosed() async throws {
        openSheet()
        let sheet = try await sendSheetChangedAndWaitForPresentation(height: 300)

        sheet.presentationControllerDidDismiss(try XCTUnwrap(sheet.presentationController))

        try await sheetClosedRecorder.waitForSheetIds(count: 1)
        XCTAssertEqual(sheetClosedRecorder.sheetIds, ["sheet-1"])
    }

    func testScreenBehindSheetGoingAwaySendsSheetClosed() async throws {
        openSheet()
        let sheet = try await sendSheetChangedAndWaitForPresentation(height: 300)

        sheet.viewDidDisappear(true)

        try await sheetClosedRecorder.waitForSheetIds(count: 1)
        XCTAssertEqual(sheetClosedRecorder.sheetIds, ["sheet-1"])
    }

    func testDismissalReportedTwiceSendsOneSheetClosed() async throws {
        openSheet()
        let sheet = try await sendSheetChangedAndWaitForPresentation(height: 300)

        sheet.viewDidDisappear(true)
        sheet.presentationControllerDidDismiss(try XCTUnwrap(sheet.presentationController))

        try await sheetClosedRecorder.waitForSheetIds(count: 1)
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(sheetClosedRecorder.sheetIds, ["sheet-1"])
    }

    func testCancelledDragDoesNotSendSheetClosed() async throws {
        openSheet()
        let sheet = try await sendSheetChangedAndWaitForPresentation(height: 300)

        sheet.viewWillDisappear(true)
        sheet.viewWillAppear(true)
        sheet.viewDidAppear(true)

        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(sheetClosedRecorder.sheetIds.isEmpty)
    }

    func testWindowCloseWhileShowingSendsSheetClosed() async throws {
        openSheet()
        let sheet = try await sendSheetChangedAndWaitForPresentation(height: 300)

        sheet.webViewDidClose(sheet.webView)

        try await sheetClosedRecorder.waitForSheetIds(count: 1)
        XCTAssertEqual(sheetClosedRecorder.sheetIds, ["sheet-1"])
        XCTAssertNil(controller.inlineSheets?.sheetWebView(for: "sheet-1"))
    }

    func testWindowCloseReleasesSheet() async throws {
        openSheet()
        weak var weakSheet: InlineSheetViewController?
        weak var weakSheetWebView: WKWebView?
        do {
            let sheet = try await sendSheetChangedAndWaitForPresentation(height: 300)
            weakSheet = sheet
            weakSheetWebView = sheet.webView
            sheet.webViewDidClose(sheet.webView)
        }
        controller.clearPresentedControllers()

        try await TestHelpers.withTimeout {
            while weakSheet != nil || weakSheetWebView != nil {
                try await Task.sleep(nanoseconds: 10_000_000)
            }
        }
        XCTAssertNil(weakSheet)
        XCTAssertNil(weakSheetWebView)
    }

    func testWindowCloseAfterDismissalDoesNotSendSecondSheetClosed() async throws {
        openSheet()
        let sheet = try await sendSheetChangedAndWaitForPresentation(height: 300)
        sheet.presentationControllerDidDismiss(try XCTUnwrap(sheet.presentationController))
        try await sheetClosedRecorder.waitForSheetIds(count: 1)

        sheet.webViewDidClose(sheet.webView)

        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(sheetClosedRecorder.sheetIds, ["sheet-1"])
        XCTAssertNil(controller.inlineSheets?.sheetWebView(for: "sheet-1"))
    }

    func testWindowCloseBeforePresentationDoesNotSendSheetClosed() async throws {
        let sheetWebView = try XCTUnwrap(openSheet())

        (sheetWebView.uiDelegate as? InlineSheetViewController)?.webViewDidClose(sheetWebView)

        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(sheetClosedRecorder.sheetIds.isEmpty)
        XCTAssertNil(controller.inlineSheets?.sheetWebView(for: "sheet-1"))
    }

    func testNativeDismissalReleasesSheet() async throws {
        openSheet()
        let sheet = try await sendSheetChangedAndWaitForPresentation(height: 300)

        sheet.presentationControllerDidDismiss(try XCTUnwrap(sheet.presentationController))

        XCTAssertNil(controller.inlineSheets?.sheetWebView(for: "sheet-1"))
    }

    func testSheetChangedAfterNativeDismissalDoesNotPresentAgain() async throws {
        openSheet()
        let sheet = try await sendSheetChangedAndWaitForPresentation(height: 300)
        sheet.presentationControllerDidDismiss(try XCTUnwrap(sheet.presentationController))

        try await sendSheetChanged(height: 300)

        XCTAssertEqual(controller.presentedControllers.count, 1)
    }

    // MARK: - Dismissible

    func testMissingDismissibleDefaultsToDismissible() async throws {
        openSheet()

        let sheet = try await sendSheetChangedAndWaitForPresentation(height: 300)

        XCTAssertFalse(sheet.isModalInPresentation)
    }

    func testNonDismissibleSheetIsModalInPresentation() async throws {
        openSheet()

        let sheet = try await sendSheetChangedAndWaitForPresentation(height: 300, dismissible: false)

        XCTAssertTrue(sheet.isModalInPresentation)
    }

    func testSheetChangedWithNonBooleanDismissibleIsIgnored() async throws {
        openSheet()

        try await controller.webView.evaluateJavaScriptAndWait("""
        window.webkit.messageHandlers.sheetChanged.postMessage({ sheetId: "sheet-1", height: 300, dismissible: "no" });
        true;
        """)

        XCTAssertTrue(controller.presentedControllers.isEmpty)
    }

    func testAttemptedDismissalOfNonDismissibleSheetSendsSheetCloseRequested() async throws {
        openSheet()
        let sheet = try await sendSheetChangedAndWaitForPresentation(height: 300, dismissible: false)

        sheet.presentationControllerDidAttemptToDismiss(try XCTUnwrap(sheet.presentationController))

        try await sheetCloseRequestedRecorder.waitForSheetIds(count: 1)
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(sheetCloseRequestedRecorder.sheetIds, ["sheet-1"])
        XCTAssertTrue(sheetClosedRecorder.sheetIds.isEmpty)
        XCTAssertNotNil(controller.inlineSheets?.sheetWebView(for: "sheet-1"))
    }

    func testDismissibleChangingToFalseWhileShownMakesSheetModal() async throws {
        openSheet()
        let sheet = try await sendSheetChangedAndWaitForPresentation(height: 300)

        try await sendSheetChanged(height: 300, dismissible: false)

        XCTAssertTrue(sheet.isModalInPresentation)
        XCTAssertEqual(controller.presentedControllers.count, 1)
    }

    func testDismissibleChangingBackToTrueAllowsNativeDismissal() async throws {
        openSheet()
        let sheet = try await sendSheetChangedAndWaitForPresentation(height: 300, dismissible: false)

        try await sendSheetChanged(height: 300, dismissible: true)
        sheet.presentationControllerDidDismiss(try XCTUnwrap(sheet.presentationController))

        XCTAssertFalse(sheet.isModalInPresentation)
        XCTAssertEqual(controller.presentedControllers.count, 1)
        try await sheetClosedRecorder.waitForSheetIds(count: 1)
        XCTAssertEqual(sheetClosedRecorder.sheetIds, ["sheet-1"])
    }

    func testWindowCloseDismissesAndReleasesNonDismissibleSheet() async throws {
        openSheet()
        weak var weakSheet: InlineSheetViewController?
        do {
            let sheet = try await sendSheetChangedAndWaitForPresentation(height: 300, dismissible: false)
            weakSheet = sheet
            sheet.webViewDidClose(sheet.webView)
        }

        try await sheetClosedRecorder.waitForSheetIds(count: 1)
        XCTAssertEqual(sheetClosedRecorder.sheetIds, ["sheet-1"])
        XCTAssertTrue(sheetCloseRequestedRecorder.sheetIds.isEmpty)
        XCTAssertNil(controller.inlineSheets?.sheetWebView(for: "sheet-1"))
        controller.clearPresentedControllers()
        try await TestHelpers.withTimeout {
            while weakSheet != nil {
                try await Task.sleep(nanoseconds: 10_000_000)
            }
        }
        XCTAssertNil(weakSheet)
    }

    func testNewComponentDocumentDismissesSheets() async throws {
        openSheet(sheetId: "sheet-1")
        _ = try await sendSheetChangedAndWaitForPresentation(height: 300)
        openSheet(sheetId: "sheet-2")

        try await controller.webView.loadTrustedDocumentPreservingDelegate()

        XCTAssertNil(controller.inlineSheets?.sheetWebView(for: "sheet-1"))
        XCTAssertNil(controller.inlineSheets?.sheetWebView(for: "sheet-2"))
    }

    func testContentProcessTerminationDismissesSheets() async throws {
        openSheet()
        _ = try await sendSheetChangedAndWaitForPresentation(height: 300)

        controller.webViewWebContentProcessDidTerminate(controller.webView)

        XCTAssertNil(controller.inlineSheets?.sheetWebView(for: "sheet-1"))
    }

    // MARK: - Sheet navigation

    func testSheetAllowsItsDocument() async throws {
        let sheet = try openSheetController()

        let policy = await sheet.webView(sheet.webView, decidePolicyFor: InlineSheetMockNavigationAction(
            url: InlineSheetTestURLs.accessoryLayer,
            targetFrame: InlineSheetMockTargetFrame(isMainFrame: true)
        ))

        XCTAssertEqual(policy, .allow)
    }

    func testSheetAllowsSameDocumentNavigation() async throws {
        let sheet = try openSheetController()

        let policy = await sheet.webView(sheet.webView, decidePolicyFor: InlineSheetMockNavigationAction(
            url: URL(string: "https://connect-js.stripe.com/accessory_layer_0123abcdef.html#step=2")!,
            targetFrame: InlineSheetMockTargetFrame(isMainFrame: true)
        ))

        XCTAssertEqual(policy, .allow)
    }

    func testSheetCancelsNavigationToAnotherOrigin() async throws {
        let sheet = try openSheetController()

        let policy = await sheet.webView(sheet.webView, decidePolicyFor: InlineSheetMockNavigationAction(
            url: URL(string: "https://foreign.example/phish.html")!,
            targetFrame: InlineSheetMockTargetFrame(isMainFrame: true)
        ))

        XCTAssertEqual(policy, .cancel)
        XCTAssertTrue(controller.presentedControllers.isEmpty)
    }

    func testSheetCancelsNavigationToAnotherPageOnConnectJSOrigin() async throws {
        let sheet = try openSheetController()

        let policy = await sheet.webView(sheet.webView, decidePolicyFor: InlineSheetMockNavigationAction(
            url: URL(string: "https://connect-js.stripe.com/v1.0/ios_webview.html")!,
            targetFrame: InlineSheetMockTargetFrame(isMainFrame: true)
        ))

        XCTAssertEqual(policy, .cancel)
    }

    func testSheetCancelsScriptedNavigationToAboutBlank() async throws {
        let sheet = try openSheetController()

        let policy = await sheet.webView(sheet.webView, decidePolicyFor: InlineSheetMockNavigationAction(
            url: URL(string: "about:blank")!,
            targetFrame: InlineSheetMockTargetFrame(isMainFrame: true)
        ))

        XCTAssertEqual(policy, .cancel)
        XCTAssertTrue(controller.presentedControllers.isEmpty)
    }

    func testSheetAllowsChildFrameNavigation() async throws {
        let sheet = try openSheetController()

        let policy = await sheet.webView(sheet.webView, decidePolicyFor: InlineSheetMockNavigationAction(
            url: URL(string: "https://js.stripe.com/v3/elements-inner.html")!,
            targetFrame: InlineSheetMockTargetFrame(isMainFrame: false)
        ))

        XCTAssertEqual(policy, .allow)
    }

    func testSheetCancelsTappedLinkNavigation() async throws {
        let sheet = try openSheetController()

        let policy = await sheet.webView(sheet.webView, decidePolicyFor: InlineSheetMockNavigationAction(
            url: URL(string: "https://support.stripe.com/questions")!,
            targetFrame: InlineSheetMockTargetFrame(isMainFrame: true),
            navigationType: .linkActivated
        ))

        XCTAssertEqual(policy, .cancel)
        XCTAssertTrue(controller.presentedControllers.isEmpty)
    }

    func testSheetNewWindowLinkUsesExistingLinkHandling() throws {
        let sheet = try openSheetController()

        let newWindow = sheet.webView(sheet.webView,
                                      createWebViewWith: sheet.webView.configuration,
                                      for: InlineSheetMockNavigationAction(url: URL(string: "https://support.stripe.com/questions")!,
                                                                           navigationType: .linkActivated),
                                      windowFeatures: WKWindowFeatures())

        XCTAssertNil(newWindow)
        XCTAssertTrue(controller.lastPresentedController is SFSafariViewController)
    }

    func testSheetCannotOpenAnotherSheet() throws {
        let sheet = try openSheetController()
        let action = InlineSheetMockNavigationAction(
            url: InlineSheetTestURLs.accessoryLayer(sheetId: "sheet-2"),
            sourceFrame: InlineSheetMockFrameInfo(isMainFrame: true, securityOrigin: componentOrigin)
        )

        let newWindow = sheet.webView(sheet.webView,
                                      createWebViewWith: sheet.webView.configuration,
                                      for: action,
                                      windowFeatures: WKWindowFeatures())

        let popup = (controller.lastPresentedController as? UINavigationController)?.topViewController as? PopupWebViewController
        popup?.webView.stopLoading()
        XCTAssertNil(controller.inlineSheets?.sheetWebView(for: "sheet-2"))
        XCTAssertNotNil(popup)
        XCTAssertTrue(popup?.webView === newWindow)
    }
}

// MARK: - Helpers

private extension InlineSheetCoordinatorTests {
    @discardableResult
    func openSheet(sheetId: String = "sheet-1",
                   url: URL? = nil,
                   sourceOrigin: WKSecurityOrigin? = nil,
                   isMainFrame: Bool = false,
                   from webView: WKWebView? = nil) -> WKWebView? {
        let action = InlineSheetMockNavigationAction(
            url: url ?? InlineSheetTestURLs.accessoryLayer(sheetId: sheetId),
            sourceFrame: InlineSheetMockFrameInfo(isMainFrame: isMainFrame, securityOrigin: sourceOrigin ?? componentOrigin)
        )
        return controller.webView(webView ?? controller.webView,
                                  createWebViewWith: controller.webView.configuration,
                                  for: action,
                                  windowFeatures: WKWindowFeatures())
    }

    func openSheetController() throws -> InlineSheetViewController {
        try XCTUnwrap(openSheet()?.navigationDelegate as? InlineSheetViewController)
    }

    func sendSheetChanged(sheetId: String = "sheet-1", height: Double, dismissible: Bool? = nil) async throws {
        let dismissibleField = dismissible.map { ", dismissible: \($0)" } ?? ""
        try await controller.webView.evaluateJavaScriptAndWait("""
        window.webkit.messageHandlers.sheetChanged.postMessage({ sheetId: "\(sheetId)", height: \(height)\(dismissibleField) });
        true;
        """)
    }

    func sendSheetChangedAndWaitForPresentation(height: Double, dismissible: Bool? = nil) async throws -> InlineSheetViewController {
        let presentationCount = controller.presentedControllers.count
        try await sendSheetChanged(height: height, dismissible: dismissible)
        return try await TestHelpers.withTimeout { @MainActor in
            while true {
                if self.controller.presentedControllers.count > presentationCount,
                   let sheet = self.controller.lastPresentedController as? InlineSheetViewController {
                    return sheet
                }
                try await Task.sleep(nanoseconds: 10_000_000)
            }
        }
    }

    func assertNoSheetOrPresentation(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNil(controller.inlineSheets?.sheetWebView(for: "sheet-1"), file: file, line: line)
        XCTAssertTrue(controller.presentedControllers.isEmpty, file: file, line: line)
    }
}

/// Records the sheet ids the SDK passes to one of Connect.js's `window` functions
private final class SheetMessageRecorder: NSObject, WKScriptMessageHandler {
    private(set) var sheetIds: [String] = []

    @MainActor
    static func install(function: String, in webView: WKWebView) async throws -> SheetMessageRecorder {
        let recorder = SheetMessageRecorder()
        let handlerName = "inlineSheetRecorder_\(function)"
        webView.configuration.userContentController.add(recorder, name: handlerName)
        try await webView.evaluateJavaScriptAndWait("""
        window.\(function) = (message) => window.webkit.messageHandlers.\(handlerName).postMessage(message);
        true;
        """)
        return recorder
    }

    @MainActor
    func waitForSheetIds(count: Int) async throws {
        try await TestHelpers.withTimeout { @MainActor in
            while self.sheetIds.count < count {
                try await Task.sleep(nanoseconds: 10_000_000)
            }
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let sheetId = body["sheetId"] as? String else { return }
        sheetIds.append(sheetId)
    }
}

private final class WindowOpenObserver: NSObject, WKScriptMessageHandler {
    static let name = "inlineSheetWindowOpenObserver"

    private var result: Bool?

    @MainActor
    func waitForResult() async throws -> Bool {
        try await TestHelpers.withTimeout { @MainActor in
            while true {
                if let result = self.result {
                    return result
                }
                try await Task.sleep(nanoseconds: 10_000_000)
            }
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        result = (message.body as? [String: Any])?["opened"] as? Bool
    }
}
