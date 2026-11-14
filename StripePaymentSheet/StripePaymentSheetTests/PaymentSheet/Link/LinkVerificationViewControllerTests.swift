//
//  LinkVerificationViewControllerTests.swift
//  StripePaymentSheetTests
//
//

import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(InternalOnlyAPI) import StripeCoreTestUtils
import UIKit
import XCTest

@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
@testable @_spi(InternalOnlyAPI) import StripePaymentsTestUtils
@testable @_spi(InternalOnlyAPI) import StripeUICore

#if !os(visionOS)
final class LinkVerificationViewControllerTests: STPNetworkStubbingTestCase {
    @MainActor
    func testStartVerification429StopsAnimatingAndShowsError() throws {
        let originalMaxRetries = StripeAPI.maxRetries
        StripeAPI.maxRetries = 0
        defer { StripeAPI.maxRetries = originalMaxRetries }

        stub(condition: isPath("/v1/consumers/sessions/start_verification")) { _ in
            LinkVerificationTestHelpers.makeStartVerificationRateLimitResponse()
        }

        let analyticsClient = STPTestingAnalyticsClient()
        let sut = makeSUT(analyticsHelper: .init(analyticsClient: analyticsClient, checkoutSessionID: "cs_test_123"))
        sut.onFinish = { _ in
            XCTFail("Delegate should not be called — user must close the view manually")
        }
        sut.loadViewIfNeeded()
        sut.coordinator.start()

        let errorDisplayedExpectation = expectation(description: "error displayed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            errorDisplayedExpectation.fulfill()
        }
        wait(for: [errorDisplayedExpectation], timeout: 2.0)

        XCTAssertFalse(sut.coordinator.isLoading)
        let failureEvent = try XCTUnwrap(analyticsClient._testLogHistory.first { $0["event"] as? String == "link.2fa.start_failure" })
        XCTAssertEqual(failureEvent["checkout_session_id"] as? String, "cs_test_123")
        XCTAssertEqual(failureEvent["verification_type"] as? String, "SMS")
        XCTAssertEqual(
            sut.coordinator.errorMessage,
            LinkUtils.ConsumerErrorCode.consumerVerificationMaxAttemptsExceeded.localizedDescription
        )
    }

    @MainActor
    func testSandboxBannerAppearsForTestAPIKey() throws {
        let sut = makeSUT(analyticsHelper: .init(), apiKey: "pk_test_auth")
        sut.loadViewIfNeeded()
        let otp = try XCTUnwrap(sut.children.first as? LinkVerificationViewController)
        let view = otp.verificationView
        view.autosizeHeight(width: 340)
        let stack = try XCTUnwrap(view.subviews.first as? UIStackView)

        let banner = try XCTUnwrap(stack.arrangedSubviews.first { $0 is LinkVerificationView.SandboxBannerView })
        XCTAssertGreaterThan(banner.bounds.height, 0)
    }

    @MainActor
    func testSandboxBannerDoesNotAppearForLiveAPIKey() throws {
        let sut = makeSUT(analyticsHelper: .init(), apiKey: "pk_live_auth")
        sut.loadViewIfNeeded()
        let otp = try XCTUnwrap(sut.children.first as? LinkVerificationViewController)
        let stack = try XCTUnwrap(otp.verificationView.subviews.first as? UIStackView)

        XCTAssertFalse(stack.arrangedSubviews.contains { $0 is LinkVerificationView.SandboxBannerView })
    }
}

private extension LinkVerificationViewControllerTests {
    @MainActor
    func makeSUT(analyticsHelper: LinkAnalyticsHelper, apiKey: String = STPTestingDefaultPublishableKey) -> LinkAuthFlowViewController {
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
            minimumAuthenticationLevel: .oneFactorAuth,
            availableVerificationFactors: [.init(type: .sms, providesFurtherVerification: true, temporarilyDisabled: false, id: "sms_factor")]
        )
        let linkAccount = PaymentSheetLinkAccount(
            email: "jane.diaz@example.com",
            session: session,
            publishableKey: "pk_test_123",
            displayablePaymentDetails: nil,
            apiClient: STPAPIClient(publishableKey: apiKey),
            useMobileEndpoints: true,
            canSyncAttestationState: false
        )

        return LinkAuthFlowViewController(linkAccount: linkAccount, brand: .link, analyticsHelper: analyticsHelper)
    }
}

#endif
