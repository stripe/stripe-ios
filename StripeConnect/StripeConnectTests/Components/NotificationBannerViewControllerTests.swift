//
//  NotificationBannerViewControllerTests.swift
//  StripeConnectTests
//
//  Created by Mel Ludowise on 10/2/24.
//

import SafariServices
@_spi(DashboardOnly) @testable import StripeConnect
@_spi(InternalOnlyAPI) import StripeCore
import WebKit
import XCTest

class NotificationBannerViewControllerTests: XCTestCase {
    let componentManager = EmbeddedComponentManager(fetchClientSecret: {
        return nil
    })

    override func setUp() {
        super.setUp()
        componentManager.shouldLoadContent = false
        componentManager.analyticsClientFactory = MockComponentAnalyticsClient.init
    }

    @MainActor
    func testDelegate() async throws {
        let vc = componentManager.createNotificationBannerViewController()

        let expectationDidFail = XCTestExpectation(description: "didFail called")
        let expectationDidChange = XCTestExpectation(description: "didChange called")

        let delegate = NotificationBannerViewControllerDelegatePassThrough { notificationBanner, error in
            XCTAssertEqual(vc, notificationBanner)
            XCTAssertEqual((error as? EmbeddedComponentError)?.type, .rateLimitError)
            XCTAssertEqual((error as? EmbeddedComponentError)?.description, "Error message")
            expectationDidFail.fulfill()
        } didChangeNotifications: { notificationBanner, total, actionRequired in
            XCTAssertEqual(vc, notificationBanner)
            XCTAssertEqual(total, 10)
            XCTAssertEqual(actionRequired, 5)
            expectationDidChange.fulfill()
        }

        vc.delegate = delegate
        try await vc.webVC.webView.loadTrustedDocumentPreservingDelegate()
        try await vc.webVC.webView.evaluateOnLoadError(type: "rate_limit_error", message: "Error message")
        try await vc.webVC.webView.evaluateNotificationsChange(total: 10, actionRequired: 5)
        await fulfillment(of: [expectationDidFail, expectationDidChange], timeout: TestHelpers.defaultTimeout * 2)
    }

    @MainActor
    func testFetchInitComponentProps() async throws {
        let vc = componentManager.createNotificationBannerViewController(
            collectionOptions: {
                var collectionOptions = AccountCollectionOptions()
                collectionOptions.fields = .eventuallyDue
                collectionOptions.futureRequirements = .include
                return collectionOptions
            }()
        )

        try await vc.webVC.webView.loadTrustedDocumentPreservingDelegate()
        try await vc.webVC.webView.evaluateMessageWithReply(name: "fetchInitComponentProps",
                                                            json: "{}",
                                                            expectedResponse: """
            {"setCollectionOptions":{"fields":"eventually_due","futureRequirements":"include"}}
            """)
    }

    // MARK: - Legacy notifications callback

    @MainActor
    func testLegacyDelegateMethodReceivesNotificationsChange() async throws {
        let vc = componentManager.createNotificationBannerViewController()
        let expectationDidChange = XCTestExpectation(description: "legacy didChange called")
        let delegate = LegacyNotificationBannerDelegate { total, actionRequired in
            XCTAssertEqual(total, 3)
            XCTAssertEqual(actionRequired, 1)
            expectationDidChange.fulfill()
        }
        vc.delegate = delegate

        try await vc.webVC.webView.loadTrustedDocumentPreservingDelegate()
        try await vc.webVC.webView.evaluateNotificationsChange(total: 3, actionRequired: 1)

        await fulfillment(of: [expectationDidChange], timeout: TestHelpers.defaultTimeout)
    }

    // MARK: - Content height

    @MainActor
    func testContentHeightIsClampedAndSizesBannerBeforeDelegate() async throws {
        let vc = componentManager.createNotificationBannerViewController()
        let delegate = ContentHeightRecorder()
        vc.delegate = delegate

        try await vc.webVC.webView.loadTrustedDocumentPreservingDelegate()
        try await vc.webVC.webView.evaluateMessage(name: "componentHeightChanged", json: "{\"height\": 25000}")

        XCTAssertEqual(delegate.heights, [10_000])
        XCTAssertEqual(delegate.intrinsicHeightsAtCallback, [10_000])
    }
}

private extension WKWebView {
    func evaluateNotificationsChange(total: Int, actionRequired: Int) async throws {
        try await evaluateMessage(name: "onSetterFunctionCalled",
                                  json: """
                                  {
                                      "setter": "setOnNotificationsChange",
                                      "value": {
                                          "total": \(total),
                                          "actionRequired": \(actionRequired)
                                      }
                                  }
                                  """)
    }
}

private class NotificationBannerViewControllerDelegatePassThrough: NotificationBannerViewControllerDelegate {

    var didFailLoad: ((_ notificationBanner: NotificationBannerViewController, _ error: Error) -> Void)?
    var didChangeNotifications: ((_ notificationBanner: NotificationBannerViewController,
                                  _ total: Int,
                                  _ actionRequired: Int) -> Void)?

    init(
        didFailLoad: ((NotificationBannerViewController, Error) -> Void)? = nil,
        didChangeNotifications: ((_ notificationBanner: NotificationBannerViewController,
                                  _ total: Int,
                                  _ actionRequired: Int) -> Void)? = nil
    ) {
        self.didFailLoad = didFailLoad
        self.didChangeNotifications = didChangeNotifications
    }

    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didFailLoadWithError error: Error) {
        didFailLoad?(notificationBanner, error)
    }

    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeNotificationsWithTotal total: Int,
                            actionRequired: Int) {
        didChangeNotifications?(notificationBanner, total, actionRequired)
    }
}

private class LegacyNotificationBannerDelegate: NotificationBannerViewControllerDelegate {
    let didChange: (_ total: Int, _ actionRequired: Int) -> Void

    init(didChange: @escaping (_ total: Int, _ actionRequired: Int) -> Void) {
        self.didChange = didChange
    }

    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeWithTotal total: Int,
                            andActionRequired actionRequired: Int) {
        didChange(total, actionRequired)
    }
}

private class ContentHeightRecorder: NotificationBannerViewControllerDelegate {
    private(set) var heights: [CGFloat] = []
    private(set) var intrinsicHeightsAtCallback: [CGFloat] = []

    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeContentHeight height: CGFloat) {
        heights.append(height)
        intrinsicHeightsAtCallback.append(notificationBanner.view.intrinsicContentSize.height)
    }
}
