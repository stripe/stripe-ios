//
//  LinkVerificationViewControllerTests.swift
//  StripePaymentSheetTests
//
//

import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(InternalOnlyAPI) import StripeCoreTestUtils
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
    func testClosingAttachedFlowDetachesWithoutCanceling() {
        // Given a dialog attached to an attempt that another host owns
        let analyticsClient = STPTestingAnalyticsClient()
        let linkAccount = makeLinkAccount()
        let coordinator = LinkAuthFlowCoordinator(account: linkAccount, analyticsHelper: .init(analyticsClient: analyticsClient))
        let sut = LinkAuthFlowViewController(sharedCoordinator: coordinator, linkAccount: linkAccount, brand: .link)
        var detachRequests = 0
        sut.onDetachRequested = { detachRequests += 1 }
        sut.onFinish = { _ in XCTFail("Closing an attached dialog shouldn't finish the attempt") }
        sut.loadViewIfNeeded()

        // When the customer closes it
        sut.close()

        // Then the host is asked to detach, and the attempt stays alive without a cancel event
        XCTAssertEqual(detachRequests, 1)
        XCTAssertFalse(coordinator.isFinished)
        XCTAssertFalse(analyticsClient._testLogHistory.contains { $0["event"] as? String == "link.2fa.cancel" })
    }

    @MainActor
    func testAttachedFlowLeavesCoordinatorCallbacksToItsHost() {
        // Given a host observing the attempt
        let linkAccount = makeLinkAccount()
        let coordinator = LinkAuthFlowCoordinator(account: linkAccount, analyticsHelper: .init(analyticsClient: STPTestingAnalyticsClient()))
        var hostUpdates = 0
        coordinator.onUpdate = { hostUpdates += 1 }

        // When a dialog attaches and the attempt changes
        let sut = LinkAuthFlowViewController(sharedCoordinator: coordinator, linkAccount: linkAccount, brand: .link)
        sut.loadViewIfNeeded()
        coordinator.prepare()

        // Then the host still receives the update
        XCTAssertGreaterThan(hostUpdates, 0)
    }

    @MainActor
    func testClosingOwnedFlowStillCancels() {
        // Given a dialog that owns its attempt
        let sut = makeSUT(analyticsHelper: .init(analyticsClient: STPTestingAnalyticsClient()))
        var result: LinkVerificationResult?
        sut.onFinish = { result = $0 }
        sut.loadViewIfNeeded()

        // When the customer closes it
        sut.close()

        // Then the attempt is canceled as before
        guard case .canceled = result else {
            return XCTFail("Expected .canceled, got \(String(describing: result))")
        }
        XCTAssertTrue(sut.coordinator.isFinished)
    }
}

private extension LinkVerificationViewControllerTests {
    @MainActor
    func makeSUT(analyticsHelper: LinkAnalyticsHelper) -> LinkAuthFlowViewController {
        LinkAuthFlowViewController(linkAccount: makeLinkAccount(), brand: .link, analyticsHelper: analyticsHelper)
    }

    func makeLinkAccount() -> PaymentSheetLinkAccount {
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
        return linkAccount
    }
}

#endif
