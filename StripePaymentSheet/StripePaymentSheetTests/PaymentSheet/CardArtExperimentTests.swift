//
//  CardArtExperimentTests.swift
//  StripePaymentSheetTests
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import XCTest

final class CardArtExperimentTests: XCTestCase {

    // MARK: - create() returns nil

    func testCreate_returnsNil_whenNoExperimentsData() {
        let session = STPElementsSession._testValue(experimentsData: nil)
        let analyticsHelper = PaymentSheetAnalyticsHelper(
            integrationShape: .complete,
            configuration: PaymentSheet.Configuration(),
            analyticsClient: STPTestingAnalyticsClient(),
            analyticsClientV2: MockAnalyticsClientV2()
        )
        let experiment = CardArtExperiment.create(
            elementsSession: session,
            configuration: PaymentSheet.Configuration(),
            analyticsHelper: analyticsHelper,
            paymentMethodTypes: [.stripe(.card)],
            savedPaymentMethods: [],
            paymentMethodOrientation: .vertical,
            selectedPaymentOption: nil
        )
        XCTAssertNil(experiment)
    }

    func testCreate_returnsNil_whenExperimentNotInAssignments() {
        let session = STPElementsSession._testValue(
            experimentsData: ExperimentsData(
                arbId: "arb_123",
                experimentAssignments: ["some_other_experiment": .treatment],
                allResponseFields: [:]
            )
        )
        let analyticsHelper = PaymentSheetAnalyticsHelper(
            integrationShape: .complete,
            configuration: PaymentSheet.Configuration(),
            analyticsClient: STPTestingAnalyticsClient(),
            analyticsClientV2: MockAnalyticsClientV2()
        )
        let experiment = CardArtExperiment.create(
            elementsSession: session,
            configuration: PaymentSheet.Configuration(),
            analyticsHelper: analyticsHelper,
            paymentMethodTypes: [.stripe(.card)],
            savedPaymentMethods: [],
            paymentMethodOrientation: .vertical,
            selectedPaymentOption: nil
        )
        XCTAssertNil(experiment)
    }

    // MARK: - create() builds correct dimensions

    func testCreate_dimensions() {
        let elementsSession = STPElementsSession._testValue(
            experimentsData: ExperimentsData(
                arbId: "arb_test",
                experimentAssignments: [CardArtExperiment.experimentName: .treatment],
                allResponseFields: [:]
            )
        )
        let analyticsHelper = PaymentSheetAnalyticsHelper(
            integrationShape: .flowController,
            configuration: PaymentSheet.Configuration(),
            analyticsClient: STPTestingAnalyticsClient(),
            analyticsClientV2: MockAnalyticsClientV2()
        )
        let cardWithArt = STPPaymentMethod._testCardWithCardArt()
        let cardNoArt = STPPaymentMethod._testCard()
        let bankPM = STPPaymentMethod._testUSBankAccount()

        let experiment = CardArtExperiment.create(
            elementsSession: elementsSession,
            configuration: PaymentSheet.Configuration(),
            analyticsHelper: analyticsHelper,
            paymentMethodTypes: [.stripe(.card), .stripe(.USBankAccount)],
            savedPaymentMethods: [cardWithArt, cardNoArt, bankPM],
            paymentMethodOrientation: .horizontal,
            selectedPaymentOption: .saved(paymentMethod: cardWithArt)
        )!

        XCTAssertEqual(experiment.name, "ocs_mobile_card_art")
        XCTAssertEqual(experiment.arbId, "arb_test")
        XCTAssertEqual(experiment.group, ExperimentGroup.treatment)

        let dims = experiment.dimensions
        XCTAssertEqual(dims["displayed_payment_method_types"], "card,us_bank_account")
        XCTAssertEqual(dims["displayed_payment_method_types_including_wallets"], "card,us_bank_account")
        XCTAssertEqual(dims["in_app_elements_integration_type"], "flowcontroller")
        XCTAssertEqual(dims["in_app_elements_layout"], "horizontal")
        XCTAssertEqual(dims["saved_payment_method_count"], "3")
        XCTAssertEqual(dims["saved_card_payment_method_count"], "2")
        XCTAssertEqual(dims["saved_card_payment_method_with_card_art_count"], "1")
        XCTAssertEqual(dims["selected_payment_method_type"], "card")
        XCTAssertEqual(dims["selected_payment_method_has_card_art"], "true")
    }

    // MARK: - selectedPaymentMethodInfo mapping

    func testSelectedPaymentMethodInfo() {
        let elementsSession = STPElementsSession._testValue(
            experimentsData: ExperimentsData(
                arbId: "arb_test",
                experimentAssignments: [CardArtExperiment.experimentName: .treatment],
                allResponseFields: [:]
            )
        )
        let analyticsHelper = PaymentSheetAnalyticsHelper(
            integrationShape: .complete,
            configuration: PaymentSheet.Configuration(),
            analyticsClient: STPTestingAnalyticsClient(),
            analyticsClientV2: MockAnalyticsClientV2()
        )
        let cases: [(SavedPaymentOptionsViewController.Selection?, String, String)] = [
            (.saved(paymentMethod: ._testCard()), "card", "false"),
            (.saved(paymentMethod: ._testCardWithCardArt()), "card", "true"),
            (nil, "none", "false"),
            (.applePay, "apple_pay", "false"),
            (.link, "link", "false"),
            (.add, "new", "false"),
        ]

        for (selection, expectedType, expectedHasArt) in cases {
            let experiment = CardArtExperiment.create(
                elementsSession: elementsSession,
                configuration: PaymentSheet.Configuration(),
                analyticsHelper: analyticsHelper,
                paymentMethodTypes: [.stripe(.card)],
                savedPaymentMethods: [],
                paymentMethodOrientation: .vertical,
                selectedPaymentOption: selection
            )!
            XCTAssertEqual(experiment.dimensions["selected_payment_method_type"], expectedType)
            XCTAssertEqual(experiment.dimensions["selected_payment_method_has_card_art"], expectedHasArt)
        }
    }
}
