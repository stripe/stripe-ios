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

final class PaymentSheetAnalyticsExperimentsTests: XCTestCase {
    private struct MockExperiment: LoggableExperiment {
        var name: String
        var arbId: String
        var group: StripePaymentSheet.ExperimentGroup
        var dimensions: [String: Any]
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
                "bool": false,
                "array": ["a", "b"],
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
        XCTAssertEqual(payload["dimensions-bool"] as? Bool, false)
        XCTAssertEqual(payload["dimensions-array"] as? [String], ["a", "b"])
    }

    func testLinkGlobalHoldback() {
        let linkSettings: LinkSettings = .init(
            fundingSources: [],
            popupWebviewOption: nil,
            passthroughModeEnabled: true,
            disableSignup: nil,
            suppress2FAModal: nil,
            useAttestationEndpoints: true,
            linkMode: .passthrough,
            linkFlags: nil,
            linkConsumerIncentive: nil,
            linkDefaultOptIn: .full,
            allResponseFields: [:]
        )
        let experimentsData = ExperimentsData(
            arbId: "arb_id_123",
            experimentAssignments: [
                "link_global_holdback": .treatment
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
            useMobileEndpoints: true
        )
        guard let experiment = LinkGlobalHoldback(
            session: session,
            configuration: configuration,
            linkAccount: linkAccount,
            integrationShape: .complete
        ) else {
            return XCTFail("Initializing a `LinkGlobalHoldback` should not fail here.")
        }

        analyticsClient.logExposure(experiment: experiment)
        guard let payload = analyticsClientV2.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName).first else {
            return XCTFail("Expected event logged with name \(PaymentSheetAnalyticsHelper.eventName)")
        }

        XCTAssertEqual(payload["arb_id"] as? String, "arb_id_123")
        XCTAssertEqual(payload["experiment_retrieved"] as? String, "link_global_holdback")
        XCTAssertEqual(payload["assignment_group"] as? String, ExperimentGroup.treatment.rawValue)

        XCTAssertEqual(payload["dimensions-recognition_type"] as? String, "email")
        XCTAssertEqual(payload["dimensions-link_native"] as? Bool, true)
        XCTAssertEqual(payload["dimensions-link_default_opt_in"] as? String, "FULL")
        XCTAssertEqual(payload["dimensions-integration_type"] as? String, "mpe_ios")
        XCTAssertEqual(payload["dimensions-dvs_provided"] as? String, "email name")
        XCTAssertEqual(payload["dimensions-is_returning_link_user"] as? Bool, false)
        XCTAssertEqual(payload["dimensions-link_displayed"] as? Bool, PaymentSheet.isLinkEnabled(elementsSession: session, configuration: configuration))
        XCTAssertEqual(payload["dimensions-integration_shape"] as? String, "paymentsheet")
        XCTAssertEqual(payload["dimensions-has_spms"] as? Bool, false)
    }
}
