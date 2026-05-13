//
//  STPPaymentHandlerCaptchaTests.swift
//  StripePaymentsTests
//

import UIKit
import XCTest

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePayments

@available(iOS 14.0, *)
class STPPaymentHandlerCaptchaTests: XCTestCase {

    // MARK: - Fixtures

    private func makePaymentIntent(captchaVendorName: String? = "arkose") -> STPPaymentIntent {
        var useStripeSDKDict: [String: Any] = ["type": "intent_confirmation_challenge"]
        if let captchaVendorName {
            useStripeSDKDict["stripe_js"] = ["captcha_vendor_name": captchaVendorName]
        }
        let apiResponse: [AnyHashable: Any] = [
            "id": "pi_test123",
            "client_secret": "pi_test123_secret_test456",
            "amount": 100,
            "currency": "usd",
            "status": "requires_action",
            "livemode": false,
            "created": 1652736692.0,
            "payment_method_types": ["card"],
            "next_action": [
                "type": "use_stripe_sdk",
                "use_stripe_sdk": useStripeSDKDict,
            ],
        ]
        return STPPaymentIntent.decodedObject(fromAPIResponse: apiResponse)!
    }

    private func makeSetupIntent(captchaVendorName: String? = "arkose") -> STPSetupIntent {
        var useStripeSDKDict: [String: Any] = ["type": "intent_confirmation_challenge"]
        if let captchaVendorName {
            useStripeSDKDict["stripe_js"] = ["captcha_vendor_name": captchaVendorName]
        }
        let apiResponse: [AnyHashable: Any] = [
            "id": "seti_test123",
            "client_secret": "seti_test123_secret_test456",
            "status": "requires_action",
            "livemode": false,
            "created": 1652736692.0,
            "payment_method_types": ["card"],
            "next_action": [
                "type": "use_stripe_sdk",
                "use_stripe_sdk": useStripeSDKDict,
            ],
        ]
        return STPSetupIntent.decodedObject(fromAPIResponse: apiResponse)!
    }

    // MARK: - VC launch tests

    func testCaptchaChallengePresentsChallengeVCForPaymentIntent() {
        let mockAPIClient = CaptchaMockAPIClient()
        mockAPIClient.publishableKey = "pk_test_abc"
        let mockPresenter = MockPresentingViewController()
        let paymentHandler = STPPaymentHandler(apiClient: mockAPIClient)
        let paymentIntent = makePaymentIntent()

        let currentAction = STPPaymentHandlerPaymentIntentActionParams(
            apiClient: mockAPIClient,
            authenticationContext: CaptchaAuthContextMock(presentingVC: mockPresenter),
            threeDSCustomizationSettings: .init(),
            paymentIntent: paymentIntent,
            returnURL: nil
        ) { _, _, _ in }
        paymentHandler.currentAction = currentAction

        paymentHandler._handleIntentConfirmationChallenge(
            stripeJs: paymentIntent.nextAction?.useStripeSDK?.stripeJs
        )

        XCTAssertTrue(
            mockPresenter.capturedPresentedVC is IntentConfirmationChallengeViewController,
            "Expected IntentConfirmationChallengeViewController to be presented"
        )
    }

    func testCaptchaChallengePresentsChallengeVCForSetupIntent() {
        let mockAPIClient = CaptchaMockAPIClient()
        mockAPIClient.publishableKey = "pk_test_abc"
        let mockPresenter = MockPresentingViewController()
        let paymentHandler = STPPaymentHandler(apiClient: mockAPIClient)
        let setupIntent = makeSetupIntent()

        let currentAction = STPPaymentHandlerSetupIntentActionParams(
            apiClient: mockAPIClient,
            authenticationContext: CaptchaAuthContextMock(presentingVC: mockPresenter),
            threeDSCustomizationSettings: .init(),
            setupIntent: setupIntent,
            returnURL: nil
        ) { _, _, _ in }
        paymentHandler.currentAction = currentAction

        paymentHandler._handleIntentConfirmationChallenge(
            stripeJs: setupIntent.nextAction?.useStripeSDK?.stripeJs
        )

        XCTAssertTrue(
            mockPresenter.capturedPresentedVC is IntentConfirmationChallengeViewController,
            "Expected IntentConfirmationChallengeViewController to be presented"
        )
    }

    // MARK: - Guard / error cases

    func testCaptchaChallengeFailsWithNilPublishableKey() {
        let mockAPIClient = CaptchaMockAPIClient()
        // publishableKey intentionally not set (nil)
        let paymentHandler = STPPaymentHandler(apiClient: mockAPIClient)
        let paymentIntent = makePaymentIntent()

        let completedExpectation = expectation(description: "completion called")
        var completedStatus: STPPaymentHandlerActionStatus?

        let currentAction = STPPaymentHandlerPaymentIntentActionParams(
            apiClient: mockAPIClient,
            authenticationContext: CaptchaAuthContextMock(),
            threeDSCustomizationSettings: .init(),
            paymentIntent: paymentIntent,
            returnURL: nil
        ) { status, _, _ in
            completedStatus = status
            completedExpectation.fulfill()
        }
        paymentHandler.currentAction = currentAction

        paymentHandler._handleIntentConfirmationChallenge(
            stripeJs: paymentIntent.nextAction?.useStripeSDK?.stripeJs
        )

        wait(for: [completedExpectation], timeout: 1.0)
        XCTAssertEqual(completedStatus, .failed)
    }
}

// MARK: - Test Helpers

class CaptchaMockAPIClient: STPAPIClient {
    var retrievePaymentIntentCalled = false
    var retrieveSetupIntentCalled = false

    override func retrievePaymentIntent(
        withClientSecret secret: String,
        expand: [String]?,
        timeout: NSNumber?,
        completion: @escaping STPPaymentIntentCompletionBlock
    ) {
        retrievePaymentIntentCalled = true
    }

    override func retrieveSetupIntent(
        withClientSecret secret: String,
        expand: [String]?,
        timeout: NSNumber?,
        completion: @escaping STPSetupIntentCompletionBlock
    ) {
        retrieveSetupIntentCalled = true
    }
}

class MockPresentingViewController: UIViewController {
    var capturedPresentedVC: UIViewController?

    override func present(
        _ viewControllerToPresent: UIViewController,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        capturedPresentedVC = viewControllerToPresent
        completion?()
    }
}

class CaptchaAuthContextMock: NSObject, STPAuthenticationContext {
    private let presentingVC: UIViewController

    init(presentingVC: UIViewController = UIViewController()) {
        self.presentingVC = presentingVC
    }

    func authenticationPresentingViewController() -> UIViewController {
        return presentingVC
    }
}
