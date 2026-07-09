//
//  PaymentSheetAnalyticsExperimentsTests.swift
//  StripePaymentSheetTests
//
//  Created by Mat Schmid on 2025-04-03.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import XCTest

@MainActor
final class PaymentSheetAnalyticsExperimentsTests: XCTestCase {
    private struct MockExperiment: LoggableExperiment {
        var name: String
        var arbId: String
        var group: StripePaymentSheet.ExperimentGroup
        var dimensions: [String: String]
    }

    private var analyticsClientV2: MockAnalyticsClientV2!
    private var analyticsClient: PaymentSheetAnalyticsHelper!

    override func setUp() {
        analyticsClientV2 = MockAnalyticsClientV2()
        analyticsClient = PaymentSheetAnalyticsHelper(
            integrationShape: .complete,
            configuration: PaymentSheet.Configuration(),
            analyticsClient: STPTestingAnalyticsClient(),
            analyticsClientV2: analyticsClientV2
        )
    }

    override func tearDown() {
        analyticsClientV2 = nil
        analyticsClient = nil
    }

    func testMockExperiment() {
        let analyticsClientV2 = MockAnalyticsClientV2()
        let analyticsClient = PaymentSheetAnalyticsHelper(
            integrationShape: .complete,
            configuration: PaymentSheet.Configuration(),
            analyticsClient: STPTestingAnalyticsClient(),
            analyticsClientV2: analyticsClientV2
        )

        let experiment = MockExperiment(
            name: "mock_experiment",
            arbId: "arb_id",
            group: .treatment,
            dimensions: [
                "string": "value",
                "bool": "false",
            ]
        )

        analyticsClient.logExposure(experiment: experiment)
        guard let payload = analyticsClientV2.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName).first else {
            return XCTFail("Expected event logged with name \(PaymentSheetAnalyticsHelper.eventName)")
        }

        XCTAssertEqual(payload["arb_id"] as? String, "arb_id")
        XCTAssertEqual(payload["experiment_retrieved"] as? String, "mock_experiment")
        XCTAssertEqual(payload["assignment_group"] as? String, ExperimentGroup.treatment.rawValue)
        XCTAssertEqual(payload["dimensions-string"] as? String, "value")
        XCTAssertEqual(payload["dimensions-bool"] as? String, "false")
    }

    func testLinkGlobalHoldback() {
        let arbId = "arb_id_123"
        let linkSettings: LinkSettings = .init(
            brand: .link,
            fundingSources: [],
            popupWebviewOption: nil,
            passthroughModeEnabled: true,
            disableSignup: nil,
            suppress2FAModal: nil,
            disableFlowControllerRUX: nil,
            useAttestationEndpoints: true,
            linkMode: .passthrough,
            linkFlags: nil,
            linkConsumerIncentive: nil,
            linkDefaultOptIn: .full,
            linkEnableDisplayableDefaultValuesInECE: nil,
            linkShowPreferDebitCardHint: nil,
            attestationStateSyncEnabled: nil,
            linkSupportedPaymentMethodsOnboardingEnabled: ["CARD"],
            allResponseFields: [:]
        )
        let experimentsData = ExperimentsData(
            arbId: arbId,
            experimentAssignments: [
                LinkGlobalHoldback.experimentName: .treatment
            ],
            allResponseFields: [:]
        )
        let session = STPElementsSession._testValue(
            linkSettings: linkSettings,
            experimentsData: experimentsData,
            customer: nil
        )
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "Test Name"
        configuration.defaultBillingDetails.email = "email"
        let linkAccount = PaymentSheetLinkAccount(
            email: "email",
            session: nil,
            publishableKey: nil,
            displayablePaymentDetails: nil,
            useMobileEndpoints: true,
            canSyncAttestationState: false
        )

        let experiment = LinkGlobalHoldback(
            arbId: arbId,
            session: session,
            configuration: configuration,
            linkAccount: linkAccount,
            integrationShape: .complete
        )
        analyticsClient.logExposure(experiment: experiment)

        guard let payload = analyticsClientV2.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName).first else {
            return XCTFail("Expected event logged with name \(PaymentSheetAnalyticsHelper.eventName)")
        }

        XCTAssertEqual(payload["arb_id"] as? String, arbId)
        XCTAssertEqual(payload["experiment_retrieved"] as? String, LinkGlobalHoldback.experimentName)
        XCTAssertEqual(payload["assignment_group"] as? String, ExperimentGroup.treatment.rawValue)

        XCTAssertEqual(payload["dimensions-recognition_type"] as? String, "email")
        XCTAssertEqual(payload["dimensions-link_native"] as? String, "true")
        XCTAssertEqual(payload["dimensions-link_default_opt_in"] as? String, "FULL")
        XCTAssertEqual(payload["dimensions-integration_type"] as? String, "mpe_ios")
        XCTAssertEqual(payload["dimensions-dvs_provided"] as? String, "email name")
        XCTAssertEqual(payload["dimensions-is_returning_link_user"] as? String, "false")
        XCTAssertEqual(payload["dimensions-link_displayed"] as? String, PaymentSheet.isLinkEnabled(elementsSession: session, configuration: configuration).description)
        XCTAssertEqual(payload["dimensions-integration_shape"] as? String, "paymentsheet")
        XCTAssertEqual(payload["dimensions-has_spms"] as? String, "false")
    }

    func testLinkABTest() {
        let arbId = "arb_id_321"
        let linkSettings: LinkSettings = .init(
            brand: .link,
            fundingSources: [],
            popupWebviewOption: nil,
            passthroughModeEnabled: true,
            disableSignup: nil,
            suppress2FAModal: nil,
            disableFlowControllerRUX: nil,
            useAttestationEndpoints: true,
            linkMode: .passthrough,
            linkFlags: nil,
            linkConsumerIncentive: nil,
            linkDefaultOptIn: .optional,
            linkEnableDisplayableDefaultValuesInECE: nil,
            linkShowPreferDebitCardHint: nil,
            attestationStateSyncEnabled: nil,
            linkSupportedPaymentMethodsOnboardingEnabled: ["CARD"],
            allResponseFields: [:]
        )
        let experimentsData = ExperimentsData(
            arbId: arbId,
            experimentAssignments: [
                "link_ab_test": .holdback
            ],
            allResponseFields: [:]
        )
        let session = STPElementsSession._testValue(
            linkSettings: linkSettings,
            experimentsData: experimentsData,
            customer: nil
        )
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.phone = "(707) 707-7070"
        let linkAccount = PaymentSheetLinkAccount(
            email: "email",
            session: LinkStubs.consumerSession(),
            publishableKey: nil,
            displayablePaymentDetails: nil,
            useMobileEndpoints: true,
            canSyncAttestationState: false
        )

        let experiment = LinkABTest(
            arbId: arbId,
            session: session,
            configuration: configuration,
            linkAccount: linkAccount,
            integrationShape: .flowController
        )
        analyticsClient.logExposure(experiment: experiment)

        guard let payload = analyticsClientV2.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName).first else {
            return XCTFail("Expected event logged with name \(PaymentSheetAnalyticsHelper.eventName)")
        }

        XCTAssertEqual(payload["arb_id"] as? String, arbId)
        XCTAssertEqual(payload["experiment_retrieved"] as? String, "link_ab_test")
        XCTAssertEqual(payload["assignment_group"] as? String, ExperimentGroup.holdback.rawValue)

        XCTAssertEqual(payload["dimensions-recognition_type"] as? String, "email")
        XCTAssertEqual(payload["dimensions-link_native"] as? String, "true")
        XCTAssertEqual(payload["dimensions-link_default_opt_in"] as? String, "OPTIONAL")
        XCTAssertEqual(payload["dimensions-integration_type"] as? String, "mpe_ios")
        XCTAssertEqual(payload["dimensions-dvs_provided"] as? String, "phone")
        XCTAssertEqual(payload["dimensions-is_returning_link_user"] as? String, "true")
        XCTAssertEqual(payload["dimensions-link_displayed"] as? String, PaymentSheet.isLinkEnabled(elementsSession: session, configuration: configuration).description)
        XCTAssertEqual(payload["dimensions-integration_shape"] as? String, "flowcontroller")
        XCTAssertEqual(payload["dimensions-has_spms"] as? String, "false")
    }
    func testPaymentMethodMessagingPromotionsExperiment_noAssignment_returnsNil() {
        let elementsSession = STPElementsSession._testValue(
            experimentsData: nil,
            customer: nil
        )

        let experiment = PaymentMethodMessagingPromotionsExperiment(
            elementsSession: elementsSession,
            layout: "vertical"
        )

        XCTAssertNil(experiment)
    }

    func testPaymentMethodMessagingPromotionsExperiment_unrelatedAssignment_returnsNil() {
        let experimentsData = ExperimentsData(
            arbId: "arb_id_123",
            experimentAssignments: [
                "some_other_experiment": .treatment,
            ],
            allResponseFields: [:]
        )
        let elementsSession = STPElementsSession._testValue(
            experimentsData: experimentsData,
            customer: nil
        )

        let experiment = PaymentMethodMessagingPromotionsExperiment(
            elementsSession: elementsSession,
            layout: "vertical"
        )

        XCTAssertNil(experiment)
    }

    func testPaymentMethodMessagingPromotionsExperiment() throws {
        let experimentsData = ExperimentsData(
            arbId: "arb_id_123",
            experimentAssignments: [
                PaymentMethodMessagingPromotionsExperiment.experimentName: .treatment
            ],
            allResponseFields: [:]
        )
        let elementsSession = STPElementsSession._testValue(
            experimentsData: experimentsData,
            customer: nil
        )

        let experiment = try XCTUnwrap(PaymentMethodMessagingPromotionsExperiment(
            elementsSession: elementsSession,
            layout: "vertical"
        ))

        XCTAssertEqual(experiment.name, PaymentMethodMessagingPromotionsExperiment.experimentName)
        XCTAssertEqual(experiment.arbId, "arb_id_123")
        XCTAssertEqual(experiment.group, .treatment)
        XCTAssertEqual(
            experiment.dimensions,
            [
                "in_app_elements_layout": "vertical",
            ]
        )
    }

    func testConnectionsFCLiteVsNative() {
        let arbId = "arb_id"
        let experimentsData = ExperimentsData(
            arbId: arbId,
            experimentAssignments: [
                ConnectionsFCLiteVsNative.experimentName: .treatment,
                ConnectionsFCLiteVsNativeAA.experimentName: .control,
            ],
            allResponseFields: [:]
        )
        let session = STPElementsSession._testValue(
            orderedPaymentMethodTypesAndWallets: ["card", "us_bank_account", "apple_pay"],
            experimentsData: experimentsData,
            customer: nil
        )

        let experiment = ConnectionsFCLiteVsNative(arbId: arbId, session: session)
        analyticsClient.logExposure(experiment: experiment)

        guard let payload = analyticsClientV2.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName).first else {
            return XCTFail("Expected event logged with name \(PaymentSheetAnalyticsHelper.eventName)")
        }

        XCTAssertEqual(payload["arb_id"] as? String, arbId)
        XCTAssertEqual(payload["experiment_retrieved"] as? String, ConnectionsFCLiteVsNative.experimentName)
        XCTAssertEqual(payload["assignment_group"] as? String, ExperimentGroup.treatment.rawValue)
        XCTAssertEqual(payload["dimensions-elements_session_id"] as? String, "test_123")
        XCTAssertNotNil(payload["dimensions-mobile_session_id"])
        XCTAssertNotNil(payload["dimensions-mobile_sdk_version"] as? String)
        XCTAssertNotNil(payload["dimensions-fc_sdk_availability"] as? String)
        XCTAssertEqual(payload["dimensions-available_lpms"] as? String, "card,us_bank_account,apple_pay")

        let aaExperiment = ConnectionsFCLiteVsNativeAA(arbId: arbId, session: session)
        XCTAssertEqual(aaExperiment.name, ConnectionsFCLiteVsNativeAA.experimentName)
        XCTAssertEqual(aaExperiment.group, .control)
    }
}
