//
//  InlineSheetCoordinatorTests.swift
//  StripeConnectTests
//

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
        controller = InlineSheetHostController(
            componentManager: EmbeddedComponentManager(apiClient: .init(publishableKey: "test"), fetchClientSecret: { nil }),
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

    func testOpensSheetForComponentWindowOnAccessoryLayerPage() {
        let sheetWebView = openSheet()

        XCTAssertNotNil(sheetWebView)
        XCTAssertTrue(controller.inlineSheets?.sheetWebView(for: "sheet-1") === sheetWebView)
    }

    func testRefusesSheetFromAnotherOrigin() async throws {
        let foreignOrigin = try await inlineSheetSecurityOrigin(for: URL(string: "https://foreign.example/frame.html")!)

        XCTAssertNil(openSheet(sourceOrigin: foreignOrigin))
        XCTAssertNil(controller.inlineSheets?.sheetWebView(for: "sheet-1"))
        XCTAssertTrue(controller.presentedControllers.isEmpty)
    }

    func testRefusesSheetForPageOutsideOriginRoot() {
        let url = URL(string: "https://connect-js.stripe.com/v1.0/accessory_layer_abc.html#os_sheet=true&os_sheet_id=sheet-1")!

        XCTAssertNil(openSheet(url: url))
        XCTAssertNil(controller.inlineSheets?.sheetWebView(for: "sheet-1"))
        XCTAssertTrue(controller.presentedControllers.isEmpty)
    }

    func testPresentsSheetOnlyAfterSheetChanged() async throws {
        let sheetWebView = openSheet()
        XCTAssertTrue(controller.presentedControllers.isEmpty)

        let sheet = try await sendSheetChangedAndWaitForPresentation(height: 20_000)

        XCTAssertTrue(sheet.webView === sheetWebView)
        XCTAssertEqual(sheet.contentHeight, 10_000)
    }

    func testDismissibleSheetSendsSheetClosedWhenDismissed() async throws {
        openSheet()
        let sheet = try await sendSheetChangedAndWaitForPresentation(height: 300)
        XCTAssertFalse(sheet.isModalInPresentation)

        sheet.presentationControllerDidDismiss(try XCTUnwrap(sheet.presentationController))

        try await sheetClosedRecorder.waitForSheetIds(count: 1)
        XCTAssertEqual(sheetClosedRecorder.sheetIds, ["sheet-1"])
        XCTAssertNil(controller.inlineSheets?.sheetWebView(for: "sheet-1"))
    }

    func testNonDismissibleSheetSendsSheetCloseRequestedAndStays() async throws {
        openSheet()
        let sheet = try await sendSheetChangedAndWaitForPresentation(height: 300, dismissible: false)
        XCTAssertTrue(sheet.isModalInPresentation)

        sheet.presentationControllerDidAttemptToDismiss(try XCTUnwrap(sheet.presentationController))

        try await sheetCloseRequestedRecorder.waitForSheetIds(count: 1)
        XCTAssertEqual(sheetCloseRequestedRecorder.sheetIds, ["sheet-1"])
        XCTAssertEqual(sheetClosedRecorder.sheetIds, [])
        XCTAssertNotNil(controller.inlineSheets?.sheetWebView(for: "sheet-1"))
    }

    func testWindowCloseSendsSheetClosedAndReleasesSheet() async throws {
        openSheet()
        weak var weakSheet: InlineSheetViewController?
        do {
            let sheet = try await sendSheetChangedAndWaitForPresentation(height: 300, dismissible: false)
            weakSheet = sheet
            sheet.webViewDidClose(sheet.webView)
        }
        controller.clearPresentedControllers()

        try await sheetClosedRecorder.waitForSheetIds(count: 1)
        XCTAssertEqual(sheetClosedRecorder.sheetIds, ["sheet-1"])
        try await TestHelpers.withTimeout {
            while weakSheet != nil {
                try await Task.sleep(nanoseconds: 10_000_000)
            }
        }
    }

    func testReloadTearsDownSheets() async throws {
        openSheet()

        try await controller.webView.loadTrustedDocumentPreservingDelegate()

        XCTAssertNil(controller.inlineSheets?.sheetWebView(for: "sheet-1"))
    }
}

private extension InlineSheetCoordinatorTests {
    @discardableResult
    func openSheet(url: URL = InlineSheetTestURLs.accessoryLayer, sourceOrigin: WKSecurityOrigin? = nil) -> WKWebView? {
        let action = InlineSheetMockNavigationAction(
            url: url,
            sourceFrame: InlineSheetMockFrameInfo(isMainFrame: false, securityOrigin: sourceOrigin ?? componentOrigin)
        )
        return controller.webView(controller.webView,
                                  createWebViewWith: controller.webView.configuration,
                                  for: action,
                                  windowFeatures: WKWindowFeatures())
    }

    func sendSheetChangedAndWaitForPresentation(height: Double, dismissible: Bool? = nil) async throws -> InlineSheetViewController {
        let dismissibleField = dismissible.map { ", dismissible: \($0)" } ?? ""
        try await controller.webView.evaluateJavaScriptAndWait("""
        window.webkit.messageHandlers.sheetChanged.postMessage({ sheetId: "sheet-1", height: \(height)\(dismissibleField) });
        true;
        """)
        return try await TestHelpers.withTimeout { @MainActor in
            while true {
                if let sheet = self.controller.lastPresentedController as? InlineSheetViewController {
                    return sheet
                }
                try await Task.sleep(nanoseconds: 10_000_000)
            }
        }
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
