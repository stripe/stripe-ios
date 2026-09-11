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
    func testStartVerification429StopsAnimatingAndShowsError() throws {
        let originalMaxRetries = StripeAPI.maxRetries
        StripeAPI.maxRetries = 0
        defer { StripeAPI.maxRetries = originalMaxRetries }

        stub(condition: isPath("/v1/consumers/sessions/start_verification")) { _ in
            LinkVerificationTestHelpers.makeStartVerificationRateLimitResponse()
        }

        let sut = makeSUT()
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
        XCTAssertEqual(
            sut.coordinator.errorMessage,
            LinkUtils.ConsumerErrorCode.consumerVerificationMaxAttemptsExceeded.localizedDescription
        )
    }
}

private extension LinkVerificationViewControllerTests {
    @MainActor
    func makeSUT() -> LinkAuthFlowViewController {
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
            apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey),
            useMobileEndpoints: true,
            canSyncAttestationState: false
        )

        return LinkAuthFlowViewController(linkAccount: linkAccount, brand: .link)
    }
}

#endif
