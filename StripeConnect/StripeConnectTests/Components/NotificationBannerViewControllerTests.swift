//
//  NotificationBannerViewControllerTests.swift
//  StripeConnectTests
//
//  Created by Mel Ludowise on 10/2/24.
//

import SafariServices
@_spi(PrivateBetaConnect) @_spi(DashboardOnly) @testable import StripeConnect
@_spi(STP) import StripeCore
import WebKit
import XCTest

class NotificationBannerViewControllerTests: XCTestCase {
    let componentManager = EmbeddedComponentManager(fetchClientSecret: {
        return nil
    })

    override func setUp() {
        super.setUp()
        STPAPIClient.shared.publishableKey = "pk_test"
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
        } didChange: { notificationBanner, total, actionRequired in
            XCTAssertEqual(vc, notificationBanner)
            XCTAssertEqual(total, 10)
            XCTAssertEqual(actionRequired, 5)
            expectationDidChange.fulfill()
        }

        vc.delegate = delegate
        try await vc.webVC.webView.evaluateOnLoadError(type: "rate_limit_error", message: "Error message")
        try await vc.webVC.webView.evaluateMessage(
            name: "onSetterFunctionCalled",
            json: """
            {
                "setter": "setOnNotificationsChange",
                "value": {
                    "total": 10,
                    "actionRequired": 5
                }
            }
            """)
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

        try await vc.webVC.webView.evaluateMessageWithReply(name: "fetchInitComponentProps",
                                                            json: "{}",
                                                            expectedResponse: """
            {"setCollectionOptions":{"fields":"eventually_due","futureRequirements":"include"}}
            """)
    }

}

private class NotificationBannerViewControllerDelegatePassThrough: NotificationBannerViewControllerDelegate {

    var didFailLoad: ((_ notificationBanner: NotificationBannerViewController, _ error: Error) -> Void)?
    var didChange: ((_ notificationBanner: NotificationBannerViewController,
                    _ total: Int,
                    _ actionRequired: Int) -> Void)?

    init(
        didFailLoad: ((NotificationBannerViewController, Error) -> Void)? = nil,
        didChange: ((_ notificationBanner: NotificationBannerViewController,
                        _ total: Int,
                        _ actionRequired: Int) -> Void)? = nil
    ) {
        self.didFailLoad = didFailLoad
        self.didChange = didChange
    }

    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didFailLoadWithError error: Error) {
        didFailLoad?(notificationBanner, error)
    }

    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeWithTotal total: Int,
                            andActionRequired actionRequired: Int) {
        didChange?(notificationBanner, total, actionRequired)
    }
}
