//
//  LinkVerificationViewControllerTests.swift
//  StripePaymentSheetTests
//
//

import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import XCTest

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils
@testable @_spi(STP) import StripeUICore

#if !os(visionOS)
final class LinkVerificationViewControllerTests: STPNetworkStubbingTestCase {
    @MainActor
    func testStartVerification429StopsAnimatingAndFinishesWithFailedResult() throws {
        let originalMaxRetries = StripeAPI.maxRetries
        StripeAPI.maxRetries = 0
        defer { StripeAPI.maxRetries = originalMaxRetries }

        stub(condition: isPath("/v1/consumers/sessions/start_verification")) { _ in
            Self.makeStartVerificationRateLimitResponse()
        }

        let finishedExpectation = expectation(description: "verification finished with failed result")
        let sut = makeSUT()
        let delegate = MockLinkVerificationViewControllerDelegate { result in
            switch result {
            case .failed(let error):
                XCTAssertEqual(error._stp_error_code, "consumer_verification_max_attempts_exceeded")
                finishedExpectation.fulfill()
            case .completed, .canceled, .switchAccount:
                XCTFail("Expected start verification to fail")
            }
        }
        sut.delegate = delegate

        sut.loadViewIfNeeded()
        sut.viewWillAppear(false)

        wait(for: [finishedExpectation], timeout: 2.0)

        let activityIndicator = try XCTUnwrap(
            sut.view.subviews.compactMap { $0 as? ActivityIndicator }.first
        )
        XCTAssertFalse(activityIndicator.isAnimating)
    }
}

private extension LinkVerificationViewControllerTests {
    static func makeStartVerificationRateLimitResponse() -> HTTPStubsResponse {
        let response: [String: Any] = [
            "error": [
                "message": "Too many attempts. Please try again in a few minutes.",
                "code": "consumer_verification_max_attempts_exceeded",
                "type": "invalid_request_error",
            ],
        ]
        return HTTPStubsResponse(
            jsonObject: response,
            statusCode: 429,
            headers: ["Content-Type": "application/json"]
        )
    }

    @MainActor
    func makeSUT() -> LinkVerificationViewController {
        let session = ConsumerSession.make(
            clientSecret: "client_secret",
            emailAddress: "jane.diaz@example.com",
            redactedFormattedPhoneNumber: "+1********55",
            unredactedPhoneNumber: nil,
            phoneNumberCountry: "US",
            verificationSessions: [],
            supportedPaymentDetailsTypes: [ParsedEnum(.card)],
            mobileFallbackWebviewParams: nil,
            currentAuthenticationLevel: .notAuthenticated,
            minimumAuthenticationLevel: .oneFactorAuth
        )
        let linkAccount = PaymentSheetLinkAccount(
            email: "jane.diaz@example.com",
            session: session,
            publishableKey: "pk_test_123",
            displayablePaymentDetails: nil,
            apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey),
            useMobileEndpoints: true,
            canSyncAttestationState: false
        )

        return LinkVerificationViewController(linkAccount: linkAccount)
    }
}

private final class MockLinkVerificationViewControllerDelegate: LinkVerificationViewControllerDelegate {
    private let onFinish: (LinkVerificationViewController.VerificationResult) -> Void

    init(onFinish: @escaping (LinkVerificationViewController.VerificationResult) -> Void) {
        self.onFinish = onFinish
    }

    func verificationController(
        _ controller: LinkVerificationViewController,
        didFinishWithResult result: LinkVerificationViewController.VerificationResult
    ) {
        onFinish(result)
    }
}
#endif
