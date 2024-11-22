//
//  AccountManagementViewControllerTests.swift
//  StripeConnectTests
//
//  Created by Mel Ludowise on 9/25/24.
//

import SafariServices
@_spi(PrivateBetaConnect) @_spi(DashboardOnly) @testable import StripeConnect
@_spi(STP) import StripeCore
import WebKit
import XCTest

class AccountManagementViewControllerTests: XCTestCase {
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
        let vc = componentManager.createAccountManagementViewController()

        let expectationDidFail = XCTestExpectation(description: "didFail called")
        let delegate = AccountManagementViewControllerDelegatePassThrough { onboardingVC, error in
            XCTAssertEqual(vc, onboardingVC)
            XCTAssertEqual((error as? EmbeddedComponentError)?.type, .rateLimitError)
            XCTAssertEqual((error as? EmbeddedComponentError)?.description, "Error message")
            expectationDidFail.fulfill()
        }

        vc.delegate = delegate
        try await vc.webVC.webView.evaluateOnLoadError(type: "rate_limit_error", message: "Error message")
        await fulfillment(of: [expectationDidFail], timeout: TestHelpers.defaultTimeout)
    }

    @MainActor
    func testFetchInitComponentProps() async throws {
        let vc = componentManager.createAccountManagementViewController(
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

private class AccountManagementViewControllerDelegatePassThrough: AccountManagementViewControllerDelegate {

    var didFailLoad: ((_ accountManagement: AccountManagementViewController, _ error: Error) -> Void)?

    init(didFailLoad: ((AccountManagementViewController, Error) -> Void)? = nil) {
        self.didFailLoad = didFailLoad
    }

    func accountManagement(_ accountManagement: AccountManagementViewController,
                           didFailLoadWithError error: Error)
    {
        didFailLoad?(accountManagement, error)
    }
}
