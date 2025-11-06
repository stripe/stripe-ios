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
            confirmHandler: { _, _ in return "" }
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
            confirmHandler: { _, _ in return "" }
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
            confirmHandler: { _, _ in return "" }
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
            confirmHandler: { _, _ in return "" }
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
            confirmHandler: { _, _ in return "" }
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
            confirmHandler: { _, _ in return "" }
        )

        let clientContext = intentConfig.createClientContext(customerId: nil)

        XCTAssertNotNil(clientContext.paymentMethodOptions)
        // The actual conversion logic may be expanded in the future
        // This test ensures the conversion method is called
    }

    // MARK: - CVC Recollection Tests

    func testCreateClientContextWithCVCRecollectionEnabled() {
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1000, currency: "usd"),
            confirmHandler: { _, _ in return "" },
            requireCVCRecollection: true
        )

        let clientContext = intentConfig.createClientContext(customerId: nil)

        XCTAssertNotNil(clientContext.paymentMethodOptions)
        let cardOptions = clientContext.paymentMethodOptions?["card"] as? [String: Any]
        XCTAssertNotNil(cardOptions)
        XCTAssertEqual(cardOptions?["require_cvc_recollection"] as? Bool, true)
    }

    func testCreateClientContextWithCVCRecollectionDisabled() {
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1000, currency: "usd"),
            confirmHandler: { _, _ in return "" },
            requireCVCRecollection: false
        )

        let clientContext = intentConfig.createClientContext(customerId: nil)

        // When requireCVCRecollection is false and no other options, paymentMethodOptions should be nil
        XCTAssertNil(clientContext.paymentMethodOptions)
    }

    func testCreateClientContextWithCVCRecollectionAndSetupFutureUsage() {
        let paymentMethodOptions = PaymentSheet.IntentConfiguration.Mode.PaymentMethodOptions(
            setupFutureUsageValues: [.card: .offSession]
        )

        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 1000,
                currency: "usd",
                paymentMethodOptions: paymentMethodOptions
            ),
            confirmHandler: { _, _ in return "" },
            requireCVCRecollection: true
        )

        let clientContext = intentConfig.createClientContext(customerId: nil)

        XCTAssertNotNil(clientContext.paymentMethodOptions)
        let cardOptions = clientContext.paymentMethodOptions?["card"] as? [String: Any]
        XCTAssertNotNil(cardOptions)
        XCTAssertEqual(cardOptions?["setup_future_usage"] as? String, "off_session")
        XCTAssertEqual(cardOptions?["require_cvc_recollection"] as? Bool, true)
    }

    func testCreateClientContextWithCVCRecollectionAndMultiplePaymentMethodOptions() {
        let paymentMethodOptions = PaymentSheet.IntentConfiguration.Mode.PaymentMethodOptions(
            setupFutureUsageValues: [
                .card: .onSession,
                .USBankAccount: .offSession,
            ]
        )

        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 1000,
                currency: "usd",
                paymentMethodOptions: paymentMethodOptions
            ),
            confirmHandler: { _, _ in return "" },
            requireCVCRecollection: true
        )

        let clientContext = intentConfig.createClientContext(customerId: nil)

        XCTAssertNotNil(clientContext.paymentMethodOptions)

        // Card should have both setup_future_usage and require_cvc_recollection
        let cardOptions = clientContext.paymentMethodOptions?["card"] as? [String: Any]
        XCTAssertNotNil(cardOptions)
        XCTAssertEqual(cardOptions?["setup_future_usage"] as? String, "on_session")
        XCTAssertEqual(cardOptions?["require_cvc_recollection"] as? Bool, true)

        // US Bank Account should only have setup_future_usage
        let usBankOptions = clientContext.paymentMethodOptions?["us_bank_account"] as? [String: Any]
        XCTAssertNotNil(usBankOptions)
        XCTAssertEqual(usBankOptions?["setup_future_usage"] as? String, "off_session")
        XCTAssertNil(usBankOptions?["require_cvc_recollection"])
    }

    func testCreateClientContextWithCVCRecollectionSetupMode() {
        // CVC recollection should only apply to payment mode, not setup mode
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .setup(),
            confirmHandler: { _, _ in return "" },
            requireCVCRecollection: true
        )

        let clientContext = intentConfig.createClientContext(customerId: nil)

        // Setup mode doesn't have paymentMethodOptions
        XCTAssertNil(clientContext.paymentMethodOptions)
    }
}
