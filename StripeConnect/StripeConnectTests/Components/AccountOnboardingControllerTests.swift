//
//  AccountOnboardingControllerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 9/19/24.
//

import SafariServices
@testable import StripeConnect
@_spi(STP) import StripeCore
import WebKit
import XCTest

class AccountOnboardingControllerTests: XCTestCase {
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

        let expectationDidFail = XCTestExpectation(description: "didFail called")
        delegate.accountOnboardingDidFailLoadWithError = { failedController, error in
            XCTAssert(controller === failedController)
            XCTAssertEqual((error as? EmbeddedComponentError)?.type, .rateLimitError)
            XCTAssertEqual((error as? EmbeddedComponentError)?.description, "Error message")
            expectationDidFail.fulfill()
        }
        try await controller.webVC.webView.evaluateOnLoadError(type: "rate_limit_error", message: "Error message")
        await fulfillment(of: [expectationDidFail], timeout: TestHelpers.defaultTimeout)
    }

    @MainActor
    func testFetchInitComponentProps() async throws {
        let controller = componentManager.createAccountOnboardingController(
            fullTermsOfServiceUrl: URL(string: "https://fullTermsOfServiceUrl.com")!,
            recipientTermsOfServiceUrl: URL(string: "https://recipientTermsOfServiceUrl.com")!,
            privacyPolicyUrl: URL(string: "https://privacyPolicyUrl.com")!,
            skipTermsOfServiceCollection: true,
            collectionOptions: {
                var collectionOptions = AccountCollectionOptions()
                collectionOptions.fields = .eventuallyDue
                collectionOptions.futureRequirements = .include
                collectionOptions.requirements = .only(["business_profile.mcc", "individual.first_name"])
                return collectionOptions
            }()
        )

        try await controller.webVC.webView.evaluateMessageWithReply(name: "fetchInitComponentProps",
                                                                    json: "{}",
                                                                    expectedResponse: """
            {"setCollectionOptions":{"fields":"eventually_due","futureRequirements":"include","requirements":{"only":["business_profile.mcc","individual.first_name"]}},"setFullTermsOfServiceUrl":"https:\\/\\/fullTermsOfServiceUrl.com","setPrivacyPolicyUrl":"https:\\/\\/privacyPolicyUrl.com","setRecipientTermsOfServiceUrl":"https:\\/\\/recipientTermsOfServiceUrl.com","setSkipTermsOfServiceCollection":true}
            """)
    }

    @MainActor
    func testControllerRetention() async {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let rootVC = UIViewController()
        window.rootViewController = rootVC
        window.makeKeyAndVisible()

        weak var weakRef: AccountOnboardingController?
        let delegate = AccountOnboardingControllerDelegatePassThrough()
        let expection = expectation(description: "Test")
        delegate.accountOnboardingDidExit = { _ in
            expection.fulfill()
        }
        autoreleasepool {
            let controller = componentManager.createAccountOnboardingController(
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
            controller.delegate = delegate
            controller.present(from: rootVC)
            weakRef = controller
        }

        XCTAssertNotNil(weakRef, "The onboarding controller should be retained during presentation")
        weakRef?.webVC.onDismiss?()

        await fulfillment(of: [expection], timeout: TestHelpers.defaultTimeout)

        XCTAssertNil(weakRef, "The onboarding controller should not be retained after dismissal")
    }

    private class AccountOnboardingControllerDelegatePassThrough: AccountOnboardingControllerDelegate {

        var accountOnboardingDidFailLoadWithError: ((_ accountOnboarding: AccountOnboardingController, _ error: Error) -> Void)?

        var accountOnboardingDidExit: ((_ accountOnboarding: AccountOnboardingController) -> Void)?

        func accountOnboarding(_ accountOnboarding: AccountOnboardingController,
                               didFailLoadWithError error: Error) {
            accountOnboardingDidFailLoadWithError?(accountOnboarding, error)
        }

        func accountOnboardingDidExit(_ accountOnboarding: AccountOnboardingController) {
            accountOnboardingDidExit?(accountOnboarding)
        }
    }
}
