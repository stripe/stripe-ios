//
//  IntentConfigurationClientContextTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 9/26/25.
//

@testable@_spi(STP) import StripePayments
@testable@_spi(STP)@_spi(PaymentMethodOptionsSetupFutureUsagePreview) import StripePaymentSheet
import XCTest

class IntentConfigurationClientContextTest: XCTestCase {

    // MARK: - Payment Mode Tests

    func testCreateClientContextFromPaymentModeMinimal() {
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1000, currency: "usd"),
            confirmHandler: { _, _, _ in }
        )

        let clientContext = intentConfig.createClientContext(customerId: nil)

        XCTAssertEqual(clientContext.mode, "payment")
        XCTAssertEqual(clientContext.currency, "usd")
        XCTAssertNil(clientContext.setupFutureUsage)
        XCTAssertEqual(clientContext.captureMethod, "automatic") // default
        XCTAssertNil(clientContext.paymentMethodOptions)
        XCTAssertNil(clientContext.paymentMethodTypes)
        XCTAssertNil(clientContext.onBehalfOf)
        XCTAssertNil(clientContext.paymentMethodConfiguration)
    }

    func testCreateClientContextFromPaymentModeComplete() {
        let paymentMethodOptions = PaymentSheet.IntentConfiguration.Mode.PaymentMethodOptions(
            setupFutureUsageValues: [.card: .offSession]
        )

        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 2000,
                currency: "eur",
                setupFutureUsage: .onSession,
                captureMethod: .manual,
                paymentMethodOptions: paymentMethodOptions
            ),
            paymentMethodTypes: ["card", "apple_pay"],
            onBehalfOf: "acct_123456",
            paymentMethodConfigurationId: "pmc_123456",
            confirmHandler: { _, _, _ in }
        )

        let clientContext = intentConfig.createClientContext(customerId: nil)

        XCTAssertEqual(clientContext.mode, "payment")
        XCTAssertEqual(clientContext.currency, "eur")
        XCTAssertEqual(clientContext.setupFutureUsage, "on_session")
        XCTAssertEqual(clientContext.captureMethod, "manual")
        XCTAssertNotNil(clientContext.paymentMethodOptions)
        XCTAssertEqual(clientContext.paymentMethodTypes, ["card", "apple_pay"])
        XCTAssertEqual(clientContext.onBehalfOf, "acct_123456")
        XCTAssertEqual(clientContext.paymentMethodConfiguration, "pmc_123456")
    }

    func testCreateClientContextFromPaymentModeWithAutomaticAsync() {
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 1500,
                currency: "gbp",
                setupFutureUsage: .offSession,
                captureMethod: .automaticAsync
            ),
            confirmHandler: { _, _, _ in }
        )

        let clientContext = intentConfig.createClientContext(customerId: nil)

        XCTAssertEqual(clientContext.mode, "payment")
        XCTAssertEqual(clientContext.currency, "gbp")
        XCTAssertEqual(clientContext.setupFutureUsage, "off_session")
        XCTAssertEqual(clientContext.captureMethod, "automatic_async")
    }

    // MARK: - Setup Mode Tests

    func testCreateClientContextFromSetupModeMinimal() {
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .setup(),
            confirmHandler: { _, _, _ in }
        )

        let clientContext = intentConfig.createClientContext(customerId: nil)

        XCTAssertEqual(clientContext.mode, "setup")
        XCTAssertNil(clientContext.currency) // default is nil for setup
        XCTAssertEqual(clientContext.setupFutureUsage, "off_session") // default for setup
        XCTAssertNil(clientContext.captureMethod) // not applicable for setup
        XCTAssertNil(clientContext.paymentMethodOptions) // not applicable for setup
        XCTAssertNil(clientContext.paymentMethodTypes)
        XCTAssertNil(clientContext.onBehalfOf)
        XCTAssertNil(clientContext.paymentMethodConfiguration)
    }

    func testCreateClientContextFromSetupModeWithCurrency() {
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .setup(currency: "cad", setupFutureUsage: .onSession),
            paymentMethodTypes: ["card"],
            onBehalfOf: "acct_789",
            paymentMethodConfigurationId: "pmc_789",
            confirmHandler: { _, _, _ in }
        )

        let clientContext = intentConfig.createClientContext(customerId: nil)

        XCTAssertEqual(clientContext.mode, "setup")
        XCTAssertEqual(clientContext.currency, "cad")
        XCTAssertEqual(clientContext.setupFutureUsage, "on_session")
        XCTAssertNil(clientContext.captureMethod) // not applicable for setup
        XCTAssertNil(clientContext.paymentMethodOptions) // not applicable for setup
        XCTAssertEqual(clientContext.paymentMethodTypes, ["card"])
        XCTAssertEqual(clientContext.onBehalfOf, "acct_789")
        XCTAssertEqual(clientContext.paymentMethodConfiguration, "pmc_789")
    }

    // MARK: - PaymentMethodOptions Conversion Tests

    func testPaymentMethodOptionsConversionWithSetupFutureUsage() {
        let paymentMethodOptions = PaymentSheet.IntentConfiguration.Mode.PaymentMethodOptions(
            setupFutureUsageValues: [
                .card: .offSession,
                .USBankAccount: .onSession,
            ]
        )

        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 1000,
                currency: "usd",
                paymentMethodOptions: paymentMethodOptions
            ),
            confirmHandler: { _, _, _ in }
        )

        let clientContext = intentConfig.createClientContext(customerId: nil)

        XCTAssertNotNil(clientContext.paymentMethodOptions)
        // The actual conversion logic may be expanded in the future
        // This test ensures the conversion method is called
    }
}
