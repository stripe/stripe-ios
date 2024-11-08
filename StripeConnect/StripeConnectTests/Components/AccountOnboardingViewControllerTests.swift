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
        componentManager.analyticsClientFactory = MockComponentAnalyticsClient.init
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
        try await vc.webVC.webView.evaluateSetOnExit()
        await fulfillment(of: [expectationDidExit], timeout: TestHelpers.defaultTimeout)

        let expectationDidFail = XCTestExpectation(description: "didFail called")
        delegate.accountOnboardingDidFailLoadWithError = { onboardingVC, error in
            XCTAssertEqual(vc, onboardingVC)
            XCTAssertEqual((error as? EmbeddedComponentError)?.type, .rateLimitError)
            XCTAssertEqual((error as? EmbeddedComponentError)?.description, "Error message")
            expectationDidFail.fulfill()
        }
        try await vc.webVC.webView.evaluateOnLoadError(type: "rate_limit_error", message: "Error message")
        await fulfillment(of: [expectationDidFail], timeout: TestHelpers.defaultTimeout)
    }

    @MainActor
    func testFetchInitComponentProps() async throws {
        let vc = componentManager.createAccountOnboardingViewController(
            fullTermsOfServiceUrl: URL(string: "https://fullTermsOfServiceUrl.com")!,
            recipientTermsOfServiceUrl: URL(string: "https://recipientTermsOfServiceUrl.com")!,
            privacyPolicyUrl: URL(string: "https://privacyPolicyUrl.com")!,
            skipTermsOfServiceCollection: true,
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
            {"setCollectionOptions":{"fields":"eventually_due","futureRequirements":"include"},"setFullTermsOfServiceUrl":"https:\\/\\/fullTermsOfServiceUrl.com","setPrivacyPolicyUrl":"https:\\/\\/privacyPolicyUrl.com","setRecipientTermsOfServiceUrl":"https:\\/\\/recipientTermsOfServiceUrl.com","setSkipTermsOfServiceCollection":true}
            """)
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
