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

    @MainActor
    func testNewDelegateMethodReplacesLegacyMethod() async throws {
        let vc = componentManager.createNotificationBannerViewController()
        let delegate = BothNotificationsCallbacksDelegate()
        vc.delegate = delegate

        try await vc.webVC.webView.loadTrustedDocumentPreservingDelegate()
        try await vc.webVC.webView.evaluateNotificationsChange(total: 3, actionRequired: 1)

        XCTAssertEqual(delegate.newCallCount, 1)
        XCTAssertEqual(delegate.legacyCallCount, 0)
    }

    // MARK: - Content height

    @MainActor
    func testContentHeightUpdatesIntrinsicContentSizeBeforeDelegate() async throws {
        let vc = componentManager.createNotificationBannerViewController()
        let delegate = ContentHeightRecorder()
        delegate.onHeight = { notificationBanner, _ in
            delegate.intrinsicHeightsAtCallback.append(notificationBanner.view.intrinsicContentSize.height)
        }
        vc.delegate = delegate

        try await vc.webVC.webView.loadTrustedDocumentPreservingDelegate()
        try await vc.webVC.webView.evaluateComponentHeightChanged("248")

        XCTAssertEqual(delegate.heights, [248])
        XCTAssertEqual(delegate.intrinsicHeightsAtCallback, [248])
    }

    @MainActor
    func testContentHeightSizesBannerViewWithAutoLayout() async throws {
        let vc = componentManager.createNotificationBannerViewController()
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(vc.view)
        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: container.topAnchor),
            vc.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])

        try await vc.webVC.webView.loadTrustedDocumentPreservingDelegate()
        try await vc.webVC.webView.evaluateComponentHeightChanged("312")
        container.layoutIfNeeded()

        XCTAssertEqual(vc.view.frame.height, 312)
        XCTAssertEqual(vc.webVC.webView.frame.height, 312)
    }

    @MainActor
    func testEmptyBannerReportsZeroHeight() async throws {
        let vc = componentManager.createNotificationBannerViewController()
        let delegate = ContentHeightRecorder()
        vc.delegate = delegate

        try await vc.webVC.webView.loadTrustedDocumentPreservingDelegate()
        try await vc.webVC.webView.evaluateComponentHeightChanged("0")

        XCTAssertEqual(delegate.heights, [0])
        XCTAssertEqual(vc.view.intrinsicContentSize.height, 0)
    }

    @MainActor
    func testUnchangedContentHeightIsReportedOnce() async throws {
        let vc = componentManager.createNotificationBannerViewController()
        let delegate = ContentHeightRecorder()
        vc.delegate = delegate

        try await vc.webVC.webView.loadTrustedDocumentPreservingDelegate()
        try await vc.webVC.webView.evaluateComponentHeightChanged("120")
        try await vc.webVC.webView.evaluateComponentHeightChanged("120")
        try await vc.webVC.webView.evaluateComponentHeightChanged("252")

        XCTAssertEqual(delegate.heights, [120, 252])
    }

    @MainActor
    func testContentHeightAboveMaximumIsClamped() async throws {
        let vc = componentManager.createNotificationBannerViewController()
        let delegate = ContentHeightRecorder()
        vc.delegate = delegate

        try await vc.webVC.webView.loadTrustedDocumentPreservingDelegate()
        try await vc.webVC.webView.evaluateComponentHeightChanged("25000")

        XCTAssertEqual(delegate.heights, [10_000])
    }

    @MainActor
    func testNegativeContentHeightIsClampedToZero() async throws {
        let vc = componentManager.createNotificationBannerViewController()
        let delegate = ContentHeightRecorder()
        vc.delegate = delegate

        try await vc.webVC.webView.loadTrustedDocumentPreservingDelegate()
        try await vc.webVC.webView.evaluateComponentHeightChanged("-40")

        XCTAssertEqual(delegate.heights, [0])
    }

    @MainActor
    func testNonNumericContentHeightIsIgnored() async throws {
        let vc = componentManager.createNotificationBannerViewController()
        let delegate = ContentHeightRecorder()
        vc.delegate = delegate

        try await vc.webVC.webView.loadTrustedDocumentPreservingDelegate()
        try await vc.webVC.webView.evaluateComponentHeightChanged("\"tall\"")
        try await vc.webVC.webView.evaluateComponentHeightChanged("80")

        XCTAssertEqual(delegate.heights, [80])
    }

    @MainActor
    func testInfiniteContentHeightIsIgnored() async throws {
        let vc = componentManager.createNotificationBannerViewController()
        let delegate = ContentHeightRecorder()
        vc.delegate = delegate

        try await vc.webVC.webView.loadTrustedDocumentPreservingDelegate()
        try await vc.webVC.webView.evaluateComponentHeightChanged("Infinity")
        try await vc.webVC.webView.evaluateComponentHeightChanged("80")

        XCTAssertEqual(delegate.heights, [80])
    }

    @MainActor
    func testNaNContentHeightIsIgnored() async throws {
        let vc = componentManager.createNotificationBannerViewController()
        let delegate = ContentHeightRecorder()
        vc.delegate = delegate

        try await vc.webVC.webView.loadTrustedDocumentPreservingDelegate()
        try await vc.webVC.webView.evaluateComponentHeightChanged("NaN")
        try await vc.webVC.webView.evaluateComponentHeightChanged("80")

        XCTAssertEqual(delegate.heights, [80])
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

    func evaluateComponentHeightChanged(_ height: String) async throws {
        try await evaluateMessage(name: "componentHeightChanged", json: "{\"height\": \(height)}")
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

private class BothNotificationsCallbacksDelegate: NotificationBannerViewControllerDelegate {
    private(set) var newCallCount = 0
    private(set) var legacyCallCount = 0

    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeNotificationsWithTotal total: Int,
                            actionRequired: Int) {
        newCallCount += 1
    }

    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeWithTotal total: Int,
                            andActionRequired actionRequired: Int) {
        legacyCallCount += 1
    }
}

private class ContentHeightRecorder: NotificationBannerViewControllerDelegate {
    private(set) var heights: [CGFloat] = []
    var intrinsicHeightsAtCallback: [CGFloat] = []
    var onHeight: ((NotificationBannerViewController, CGFloat) -> Void)?

    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeContentHeight height: CGFloat) {
        heights.append(height)
        onHeight?(notificationBanner, height)
    }
}
