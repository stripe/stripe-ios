//
//  IntentConfirmationChallengeViewControllerTests.swift
//  StripePaymentsTests
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

    func testHandleSuccessCompletionCalledOnce() {
        var callCount = 0
        let vc = makeVC { _ in callCount += 1 }
        vc.handleSuccess()
        XCTAssertEqual(callCount, 1)
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

    func testHandleErrorWithUnknownErrorCallsCompletionWithFailure() {
        var result: Result<Void, Error>?
        let vc = makeVC { result = $0 }
        vc.handleError(ChallengeError.unknownError)

        guard case .failure(let error) = result,
              let challengeError = error as? ChallengeError,
              case .unknownError = challengeError else {
            XCTFail("Expected .failure(.unknownError), got \(String(describing: result))")
            return
        }
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

}
