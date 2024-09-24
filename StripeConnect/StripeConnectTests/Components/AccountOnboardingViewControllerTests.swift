//
//  AccountOnboardingViewControllerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 9/19/24.
//

import SafariServices
@_spi(PrivateBetaConnect) @testable import StripeConnect
@_spi(STP) import StripeCore
import WebKit
import XCTest

class AccountOnboardingViewControllerTests: XCTestCase {
    let componentManager = EmbeddedComponentManager(fetchClientSecret: {
        return nil
    })

    override func setUp() {
        super.setUp()
        STPAPIClient.shared.publishableKey = "pk_test"
        componentManager.shouldLoadContent = false
    }

    @MainActor
    func testDelegate() async throws {
        let delegate = AccountOnboardingViewControllerDelegatePassThrough()
        let vc = componentManager.createAccountOnboardingViewController()
        vc.delegate = delegate

        let expectationDidExit = XCTestExpectation(description: "didExit called")
        delegate.accountOnboardingDidExit = { onboardingVC in
            XCTAssertEqual(vc, onboardingVC)
            expectationDidExit.fulfill()
        }
        try await vc.webView.evaluateSetOnExit()
        await fulfillment(of: [expectationDidExit], timeout: TestHelpers.defaultTimeout)

        let expectationDidFail = XCTestExpectation(description: "didFail called")
        delegate.accountOnboardingDidFailLoadWithError = { onboardingVC, error in
            XCTAssertEqual(vc, onboardingVC)
            XCTAssertEqual((error as? EmbeddedComponentError)?.type, .rateLimitError)
            XCTAssertEqual((error as? EmbeddedComponentError)?.description, "Error message")
            expectationDidFail.fulfill()
        }
        try await vc.webView.evaluateOnLoadError(type: "rate_limit_error", message: "Error message")
        await fulfillment(of: [expectationDidFail], timeout: TestHelpers.defaultTimeout)
    }

    private class AccountOnboardingViewControllerDelegatePassThrough: AccountOnboardingViewControllerDelegate {

        var accountOnboardingDidExit: ((_ accountOnboarding: AccountOnboardingViewController) -> Void)?

        var accountOnboardingDidFailLoadWithError: ((_ accountOnboarding: AccountOnboardingViewController, _ error: Error) -> Void)?

        func accountOnboardingDidExit(_ accountOnboarding: AccountOnboardingViewController) {
            accountOnboardingDidExit?(accountOnboarding)
        }

        func accountOnboarding(_ accountOnboarding: AccountOnboardingViewController,
                               didFailLoadWithError error: Error)
        {
            accountOnboardingDidFailLoadWithError?(accountOnboarding, error)
        }
    }

}
