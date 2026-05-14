//
//  IntentConfirmationChallengeViewControllerTests.swift
//  StripePaymentsTests
//
//  Created by Joyce Qin on 5/14/26.
//

import XCTest

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePayments

@available(iOS 14.0, *)
class IntentConfirmationChallengeViewControllerTests: XCTestCase {

    private func makeVC(
        intentType: IntentType = .paymentIntent(id: "pi_test123"),
        apiClient: STPAPIClient = STPAPIClient(publishableKey: "pk_test_abc"),
        stripeJs: STPIntentActionUseStripeSDK.StripeJS? = nil,
        completion: @escaping (Result<Void, Error>) -> Void = { _ in }
    ) -> IntentConfirmationChallengeViewController {
        let vc = IntentConfirmationChallengeViewController(
            publishableKey: "pk_test_abc",
            clientSecret: "pi_test123_secret_test456",
            intentType: intentType,
            apiClient: apiClient,
            stripeJs: stripeJs,
            completion: completion
        )
        _ = vc.view  // trigger viewDidLoad
        return vc
    }

    // MARK: - handleSuccess

    func testHandleSuccessCallsCompletionWithSuccess() {
        var result: Result<Void, Error>?
        let vc = makeVC { result = $0 }
        vc.handleSuccess()

        guard case .success = result else {
            XCTFail("Expected .success, got \(String(describing: result))")
            return
        }
    }

    // MARK: - handleError

    func testHandleErrorCallsCompletionWithFailure() {
        var result: Result<Void, Error>?
        let vc = makeVC { result = $0 }
        vc.handleError(ChallengeError.webError(message: "failed", type: "arkose_error", code: "ERR_1"))

        guard case .failure(let error) = result,
              let challengeError = error as? ChallengeError,
              case .webError(let msg, _, _) = challengeError else {
            XCTFail("Expected .failure(.webError), got \(String(describing: result))")
            return
        }
        XCTAssertEqual(msg, "failed")
    }

    // MARK: - handleReady

    func testHandleReadyDoesNotCallCompletion() {
        var completionCalled = false
        let vc = makeVC { _ in completionCalled = true }
        vc.handleReady()
        XCTAssertFalse(completionCalled)
    }

    // MARK: - closeButtonTapped

    func testCloseButtonTappedCompletesWithUserCanceled() {
        var result: Result<Void, Error>?
        let vc = makeVC { result = $0 }
        vc.closeButtonTapped()

        guard case .failure(let error) = result,
              let challengeError = error as? ChallengeError,
              case .userCanceled = challengeError else {
            XCTFail("Expected .failure(.userCanceled), got \(String(describing: result))")
            return
        }
    }

    // MARK: - ChallengeError: analyticsErrorType

    func testWebErrorAnalyticsTypeUsesProvidedType() {
        let error = ChallengeError.webError(message: "msg", type: "arkose_error", code: "1234")
        XCTAssertEqual(error.analyticsErrorType, "arkose_error")
    }

    func testNonWebErrorsUseDefaultAnalyticsType() {
        let underlying = NSError(domain: "test", code: 1)
        XCTAssertEqual(ChallengeError.userCanceled.analyticsErrorType, "IntentConfirmationChallengeError")
        XCTAssertEqual(ChallengeError.unknownError.analyticsErrorType, "IntentConfirmationChallengeError")
        XCTAssertEqual(ChallengeError.navigationFailed(underlying).analyticsErrorType, "IntentConfirmationChallengeError")
    }

    // MARK: - ChallengeError: analyticsErrorCode

    func testWebErrorAnalyticsCodeUsesProvidedCode() {
        let error = ChallengeError.webError(message: "msg", type: "type", code: "MY_CODE")
        XCTAssertEqual(error.analyticsErrorCode, "MY_CODE")
    }

    func testWebErrorAnalyticsCodeNilDefaultsToUnknown() {
        let error = ChallengeError.webError(message: "msg", type: "type", code: nil)
        XCTAssertEqual(error.analyticsErrorCode, "unknown")
    }

    // MARK: - ChallengeError: additionalNonPIIErrorDetails

    func testWebErrorAdditionalDetailsHasFromBridgeTrue() {
        let error = ChallengeError.webError(message: "msg", type: "type", code: nil)
        XCTAssertEqual(error.additionalNonPIIErrorDetails["from_bridge"] as? Bool, true)
    }

    func testNonWebErrorsAdditionalDetailsHaveFromBridgeFalse() {
        let underlying = NSError(domain: "test", code: 1)
        XCTAssertEqual(ChallengeError.userCanceled.additionalNonPIIErrorDetails["from_bridge"] as? Bool, false)
        XCTAssertEqual(ChallengeError.unknownError.additionalNonPIIErrorDetails["from_bridge"] as? Bool, false)
        XCTAssertEqual(ChallengeError.navigationFailed(underlying).additionalNonPIIErrorDetails["from_bridge"] as? Bool, false)
    }

    // MARK: - ChallengeError: errorDescription

    func testWebErrorDescriptionUsesMessage() {
        let error = ChallengeError.webError(message: "Captcha verification failed", type: "type", code: nil)
        XCTAssertEqual(error.errorDescription, "Captcha verification failed")
    }

    func testNavigationFailedDescriptionIncludesUnderlyingError() {
        let underlying = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Connection lost"])
        let error = ChallengeError.navigationFailed(underlying)
        XCTAssertEqual(error.errorDescription, "Navigation failed: Connection lost")
    }

    func testUserCanceledDescriptionIsNil() {
        XCTAssertNil(ChallengeError.userCanceled.errorDescription)
    }

    func testUnknownErrorHasDescription() {
        XCTAssertEqual(ChallengeError.unknownError.errorDescription, "Unknown error.")
    }
}
