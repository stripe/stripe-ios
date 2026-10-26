//
//  LinkVerificationViewControllerTests.swift
//  StripePaymentSheetTests
//
//

import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(STP) import StripeCoreTestUtils
import XCTest

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils
@testable @_spi(STP) import StripeUICore

#if !os(visionOS)
final class LinkVerificationViewControllerTests: STPNetworkStubbingTestCase {
    @MainActor
    func testStartVerification429StopsAnimatingAndShowsError() throws {
        let analyticsClient = STPTestingAnalyticsClient()
        let originalMaxRetries = StripeAPI.maxRetries
        StripeAPI.maxRetries = 0
        defer { StripeAPI.maxRetries = originalMaxRetries }

        stub(condition: isPath("/v1/consumers/sessions/start_verification")) { _ in
            LinkVerificationTestHelpers.makeStartVerificationRateLimitResponse()
        }

        let sut = makeSUT(analyticsHelper: .init(analyticsClient: analyticsClient, checkoutSessionID: "cs_test_123"))
        let delegate = MockLinkVerificationViewControllerDelegate { _ in
            XCTFail("Delegate should not be called — user must close the view manually")
        }
        sut.delegate = delegate

        sut.loadViewIfNeeded()
        sut.viewWillAppear(false)

        let errorDisplayedExpectation = expectation(description: "error displayed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            errorDisplayedExpectation.fulfill()
        }
        wait(for: [errorDisplayedExpectation], timeout: 2.0)

        let activityIndicator = try XCTUnwrap(
            sut.view.subviews.compactMap { $0 as? ActivityIndicator }.first
        )
        XCTAssertFalse(activityIndicator.isAnimating)
        let failureEvent = try XCTUnwrap(analyticsClient._testLogHistory.first { $0["event"] as? String == "link.2fa.start_failure" })
        XCTAssertEqual(failureEvent["checkout_session_id"] as? String, "cs_test_123")

        let verificationView = try XCTUnwrap(
            sut.view.subviews.compactMap { $0 as? LinkVerificationView }.first
        )
        XCTAssertFalse(verificationView.isHidden)
        XCTAssertEqual(
            verificationView.errorMessage,
            LinkUtils.ConsumerErrorCode.consumerVerificationMaxAttemptsExceeded.localizedDescription
        )
    }
}

private extension LinkVerificationViewControllerTests {
    @MainActor
    func makeSUT(analyticsHelper: LinkAnalyticsHelper) -> LinkVerificationViewController {
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

        return LinkVerificationViewController(linkAccount: linkAccount, analyticsHelper: analyticsHelper)
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
