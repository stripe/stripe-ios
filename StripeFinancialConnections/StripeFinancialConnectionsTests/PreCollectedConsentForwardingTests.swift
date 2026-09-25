//
//  PreCollectedConsentForwardingTests.swift
//  StripeFinancialConnectionsTests
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@testable import StripeFinancialConnections
import XCTest

final class PreCollectedConsentForwardingTests: XCTestCase {
    @MainActor
    func testLaterSynchronizeOmitsEvidenceAfterInitialSynchronize() {
        // Given a launch with pre-collected consent
        let apiClient = RecordingFinancialConnectionsAPIClient()
        let evidence = FinancialConnectionsPreCollectedConsent(
            consent: "fccons_123",
            collectedAt: 1_725_000_123
        )
        let hostViewController = HostViewController(
            analyticsClientV1: MockAnalyticsClient(),
            clientSecret: "las_client_secret_123",
            returnURL: nil,
            apiClient: apiClient,
            preCollectedConsent: evidence,
            delegate: nil
        )

        // When initialization and a later Link login Synchronize occur
        hostViewController.loadViewIfNeeded()
        let linkLoginDataSource = LinkLoginDataSourceImplementation(
            manifest: makeManifest(),
            analyticsClient: FinancialConnectionsAnalyticsClient(analyticsClient: MockAnalyticsClientV2()),
            clientSecret: "las_client_secret_123",
            returnURL: nil,
            apiClient: apiClient,
            elementsSessionContext: nil
        )
        _ = linkLoginDataSource.synchronize()

        // Then evidence is attached only to the initial request
        XCTAssertEqual(apiClient.synchronizeCalls.count, 2)
        XCTAssertTrue(apiClient.synchronizeCalls[0].initialSynchronize)
        XCTAssertEqual(apiClient.synchronizeCalls[0].preCollectedConsent?.consent, "fccons_123")
        XCTAssertEqual(apiClient.synchronizeCalls[0].preCollectedConsent?.collectedAt, 1_725_000_123)
        XCTAssertFalse(apiClient.synchronizeCalls[1].initialSynchronize)
        XCTAssertNil(apiClient.synchronizeCalls[1].preCollectedConsent)
    }

    private func makeManifest() -> FinancialConnectionsSessionManifest {
        FinancialConnectionsSessionManifest(
            accountholderCustomerEmailAddress: nil,
            accountholderIsLinkConsumer: nil,
            accountholderPhoneNumber: nil,
            accountholderToken: nil,
            accountDisconnectionMethod: nil,
            activeAuthSession: nil,
            activeInstitution: nil,
            allowManualEntry: false,
            appVerificationEnabled: nil,
            assignmentEventId: nil,
            linkBrand: nil,
            businessName: nil,
            cancelUrl: nil,
            consentAcquiredAt: nil,
            consentRequired: false,
            customManualEntryHandling: false,
            disableLinkMoreAccounts: false,
            displayText: nil,
            experimentAssignments: nil,
            features: nil,
            hostedAuthUrl: nil,
            id: "fcsess_123",
            initialInstitution: nil,
            instantVerificationDisabled: false,
            institutionSearchDisabled: false,
            isEndUserFacing: nil,
            isLinkWithStripe: nil,
            isNetworkingUserFlow: nil,
            isStripeDirect: nil,
            livemode: false,
            manualEntryMode: .automatic,
            manualEntryUsesMicrodeposits: false,
            nextPane: ParsedEnum(.linkLogin),
            paymentMethodType: nil,
            permissions: [],
            product: "external_api",
            singleAccount: false,
            skipSuccessPane: nil,
            successUrl: nil,
            theme: nil
        )
    }
}

private final class RecordingFinancialConnectionsAPIClient: EmptyFinancialConnectionsAPIClient {
    struct SynchronizeCall {
        let initialSynchronize: Bool
        let preCollectedConsent: FinancialConnectionsPreCollectedConsent?
    }

    var synchronizeCalls: [SynchronizeCall] = []

    override func synchronize(
        clientSecret: String,
        returnURL: String?,
        initialSynchronize: Bool,
        preCollectedConsent: FinancialConnectionsPreCollectedConsent?
    ) -> Future<FinancialConnectionsSynchronize> {
        synchronizeCalls.append(
            SynchronizeCall(
                initialSynchronize: initialSynchronize,
                preCollectedConsent: preCollectedConsent
            )
        )
        return Promise<FinancialConnectionsSynchronize>()
    }
}
