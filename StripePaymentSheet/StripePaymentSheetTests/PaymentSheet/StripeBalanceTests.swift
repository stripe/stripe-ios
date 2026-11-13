//
//  StripeBalanceTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 11/12/26.
//

import XCTest

@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripeUICore

@MainActor
final class StripeBalanceTests: XCTestCase {

    // MARK: - Availability

    func testRequiresCustomerSessionAndDoesNotSupportSetup() {
        // Given
        let paymentIntent = Intent._testPaymentIntent(paymentMethodTypes: [.stripeBalance])
        var legacyCustomerConfiguration = PaymentSheet.Configuration()
        legacyCustomerConfiguration.customer = .init(id: "cus_123", ephemeralKeySecret: "ek_123")

        // When
        let withoutCustomer = supportsAdding(intent: paymentIntent, configuration: PaymentSheet.Configuration())
        let withLegacyEphemeralKey = supportsAdding(intent: paymentIntent, configuration: legacyCustomerConfiguration)
        let withCustomerSession = supportsAdding(intent: paymentIntent, configuration: makeCustomerSessionConfiguration())

        // Then
        XCTAssertEqual(withoutCustomer, .missingRequirements([.customerSession]))
        XCTAssertEqual(withLegacyEphemeralKey, .missingRequirements([.customerSession]))
        XCTAssertEqual(withCustomerSession, .supported)
        let setupIntents: [Intent] = [
            ._testPaymentIntent(paymentMethodTypes: [.stripeBalance], setupFutureUsage: .offSession),
            ._testSetupIntent(paymentMethodTypes: [.stripeBalance]),
        ]
        for intent in setupIntents {
            XCTAssertEqual(
                supportsAdding(intent: intent, configuration: makeCustomerSessionConfiguration()),
                .missingRequirements([.unsupportedForSetup])
            )
        }
    }

    // MARK: - Helpers

    private func makeCustomerSessionConfiguration() -> PaymentSheet.Configuration {
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "cus_123", customerSessionClientSecret: "cuss_123_secret_456")
        return configuration
    }

    private func supportsAdding(intent: Intent, configuration: PaymentSheet.Configuration) -> PaymentSheet.PaymentMethodAvailabilityStatus {
        PaymentSheet.PaymentMethodType.supportsAdding(
            paymentMethod: .stripeBalance,
            configuration: configuration,
            intent: intent,
            elementsSession: ._testValue(intent: intent),
            supportedPaymentMethods: [.stripeBalance]
        )
    }
}
