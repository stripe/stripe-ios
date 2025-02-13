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
        let delegate = AccountOnboardingControllerDelegatePassThrough()
        let controller = componentManager.createAccountOnboardingController()
        controller.delegate = delegate

        let expectationDidExit = XCTestExpectation(description: "didExit called")
        delegate.accountOnboardingDidExit = { onboarding in
            XCTAssert(controller === onboarding)

            expectationDidExit.fulfill()
        }
        
        controller.webVC.onDismiss?()
//        try await controller.webVC.webView.evaluateSetOnExit()
        await fulfillment(of: [expectationDidExit], timeout: TestHelpers.defaultTimeout)

        let expectationDidFail = XCTestExpectation(description: "didFail called")
        delegate.accountOnboardingDidFailLoadWithError = { onboardingVC, error in
            XCTAssert(controller === onboardingVC)
            XCTAssertEqual((error as? EmbeddedComponentError)?.type, .rateLimitError)
            XCTAssertEqual((error as? EmbeddedComponentError)?.description, "Error message")
            expectationDidFail.fulfill()
        }
        try await controller.webVC.webView.evaluateOnLoadError(type: "rate_limit_error", message: "Error message")
        await fulfillment(of: [expectationDidFail], timeout: TestHelpers.defaultTimeout)
    }

    @MainActor
    func testFetchInitComponentProps() async throws {
        let vc = componentManager.createAccountOnboardingController(
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

    private class AccountOnboardingControllerDelegatePassThrough: AccountOnboardingControllerDelegate {

        var accountOnboardingDidRequestDismissalFromUser: ((_ accountOnboarding: AccountOnboardingController) -> Void)?

        var accountOnboardingDidFailLoadWithError: ((_ accountOnboarding: AccountOnboardingController, _ error: Error) -> Void)?
        
        var accountOnboardingDidExit: ((_ accountOnboarding: AccountOnboardingController)->Void)? = nil
        
        func accountOnboardingDidRequestDismissalFromUser(_ accountOnboarding: AccountOnboardingController) {
            accountOnboardingDidRequestDismissalFromUser?(accountOnboarding)
        }

        func accountOnboarding(_ accountOnboarding: AccountOnboardingController,
                               didFailLoadWithError error: Error)
        {
            accountOnboardingDidFailLoadWithError?(accountOnboarding, error)
        }
        
        func accountOnboardingDidExit(_ accountOnboarding: AccountOnboardingController) {
            accountOnboardingDidExit?(accountOnboarding)
        }
    }

}
