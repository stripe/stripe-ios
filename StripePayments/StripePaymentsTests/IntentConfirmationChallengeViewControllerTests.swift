//
//  IntentConfirmationChallengeViewControllerTests.swift
//  StripePaymentsTests
//
//  Created by Joyce Qin on 5/14/26.
//

import WebKit
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
        _ = vc.view
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

    // MARK: - WKNavigationDelegate

    func testWebViewNavigationFailureCallsCompletionWithNavigationFailed() {
        let underlyingError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        var result: Result<Void, Error>?
        let vc = makeVC { result = $0 }
        vc.webView(WKWebView(), didFail: nil, withError: underlyingError)

        guard case .failure(let error) = result,
              let challengeError = error as? ChallengeError,
              case .navigationFailed = challengeError else {
            XCTFail("Expected .failure(.navigationFailed), got \(String(describing: result))")
            return
        }
    }

    func testWebViewProvisionalNavigationFailureCallsCompletionWithNavigationFailed() {
        let underlyingError = NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotFindHost)
        var result: Result<Void, Error>?
        let vc = makeVC { result = $0 }
        vc.webView(WKWebView(), didFailProvisionalNavigation: nil, withError: underlyingError)

        guard case .failure(let error) = result,
              let challengeError = error as? ChallengeError,
              case .navigationFailed = challengeError else {
            XCTFail("Expected .failure(.navigationFailed), got \(String(describing: result))")
            return
        }
    }

    // MARK: - ChallengeError: analyticsErrorCode

    func testWebErrorAnalyticsCodeNilDefaultsToUnknown() {
        let error = ChallengeError.webError(message: "msg", type: "type", code: nil)
        XCTAssertEqual(error.analyticsErrorCode, "unknown")
    }

    // MARK: - ChallengeError: errorDescription

    func testNavigationFailedDescriptionIncludesUnderlyingError() {
        let underlying = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Connection lost"])
        XCTAssertEqual(ChallengeError.navigationFailed(underlying).errorDescription, "Navigation failed: Connection lost")
    }

    func testUserCanceledDescriptionIsNil() {
        XCTAssertNil(ChallengeError.userCanceled.errorDescription)
    }
}
