//
//  PaymentSheet+PaymentMethodAvailabilityTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 1/22/25.
//

@testable @_spi(STP) import StripePaymentSheet
import XCTest

final class PaymentMethodAvailabilityTest: XCTestCase {

    func testIsLinkEnabled_supportsLinkFalse_linkNotPresent() {
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card"],
            isLinkPassthroughModeEnabled: false
        )
        let configuration = PaymentSheet.Configuration()
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)

        XCTAssertFalse(isLinkEnabled, "Link should be disabled when supportsLink is false and link is not in payment method types")
    }

    func testIsLinkEnabled_supportsLinkTrue_linkPresent() {
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card", "link"],
            isLinkPassthroughModeEnabled: false
        )
        let configuration = PaymentSheet.Configuration()
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)

        XCTAssertTrue(isLinkEnabled, "Link should be enabled when isLinkPassthroughModeEnabled is false, since Link is present in the payment method types")
    }

    func testIsLinkEnabled_supportsLinkTrue_linkNotPresent_passthroughEnabled() {
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card"],
            isLinkPassthroughModeEnabled: true
        )
        let configuration = PaymentSheet.Configuration()
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)

        XCTAssertTrue(isLinkEnabled, "Link should be enabled when supportsLink is true because passthrough mode is enabled")
    }

    func testIsLinkEnabled_requiresBillingDetailCollection() {
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card", "link"],
            isLinkPassthroughModeEnabled: true

        )
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .always
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)

        XCTAssertFalse(isLinkEnabled, "Link should be disabled when billing details collection is required")
    }

    func testIsLinkEnabled_cardBrandAcceptanceNotAll() {
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card", "link"],
            isLinkPassthroughModeEnabled: true

        )
        var configuration = PaymentSheet.Configuration()
        configuration.cardBrandAcceptance = .allowed(brands: [.visa])
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)

        XCTAssertFalse(isLinkEnabled, "Link should be disabled when card brand acceptance is not 'all'")
    }

    func testIsLinkEnabled_allConditionsMet() {
        // Given
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card", "link"],
            isLinkPassthroughModeEnabled: true
        )
        let configuration = PaymentSheet.Configuration()
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)

        XCTAssertTrue(isLinkEnabled, "Link should be enabled when all conditions are met")
    }

    func testIsLinkEnabled_linkNotExplicitlyAllowedButPassthroughEnabled() {
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card"],
            isLinkPassthroughModeEnabled: true
        )
        let configuration = PaymentSheet.Configuration()
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)

        XCTAssertTrue(isLinkEnabled, "Link should be enabled when passthrough mode is enabled, even if 'link' is not explicitly in payment method types")
    }
}
