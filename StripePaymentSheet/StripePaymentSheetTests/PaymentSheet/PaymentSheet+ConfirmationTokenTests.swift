//
//  PaymentSheet+ConfirmationTokenTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 9/25/25.
//

import Foundation
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripeCoreTestUtils
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) @_spi(SharedPaymentToken) @_spi(PaymentMethodOptionsSetupFutureUsagePreview) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripeUICore
import XCTest

final class PaymentSheet_ConfirmationTokenTests: STPNetworkStubbingTestCase {

    var apiClient: STPAPIClient!

    override func setUp() {
        super.setUp()
        apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
    }

    // MARK: - Test Helpers

    lazy var configuration: PaymentSheet.Configuration = {
        var config = PaymentSheet.Configuration()
        config.apiClient = apiClient
        config.allowsDelayedPaymentMethods = true
        config.shippingDetails = {
            return .init(
                address: .init(
                    country: "US",
                    line1: "Line 1"
                ),
                name: "Jane Doe",
                phone: "5551234567"
            )
        }
        return config
    }()

    lazy var configurationWithoutShipping: PaymentSheet.Configuration = {
        var config = PaymentSheet.Configuration()
        config.apiClient = apiClient
        config.allowsDelayedPaymentMethods = true
        return config
    }()

    func createTestIntentConfig(mode: PaymentSheet.IntentConfiguration.Mode) -> PaymentSheet.IntentConfiguration {
        return PaymentSheet.IntentConfiguration(mode: mode) { _, _ in
            return "pi_test_123_secret_abc"
        }
    }

    func createTestSavedPaymentMethod() -> STPPaymentMethod {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_test_123",
            "type": "card",
            "card": [
                "brand": "visa",
                "last4": "4242",
                "exp_month": 12,
                "exp_year": 2025,
            ],
        ])!
        return paymentMethod
    }

    func createTestPaymentMethodParams() -> STPPaymentMethodParams {
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.cvc = "123"
        cardParams.expYear = 32
        cardParams.expMonth = 12

        return STPPaymentMethodParams(
            card: cardParams,
            billingDetails: STPPaymentMethodBillingDetails(),
            metadata: nil
        )
    }

    func createTestSavedConfirmType() -> PaymentSheet.ConfirmPaymentMethodType {
        return .saved(
            createTestSavedPaymentMethod(),
            paymentOptions: nil,
            clientAttributionMetadata: nil
        )
    }

    func createTestNewConfirmType(shouldSave: Bool = false, shouldSetAsDefaultPM: Bool? = nil) -> PaymentSheet.ConfirmPaymentMethodType {
        return .new(
            params: createTestPaymentMethodParams(),
            paymentOptions: STPConfirmPaymentMethodOptions(),
            paymentMethod: nil,
            shouldSave: shouldSave,
            shouldSetAsDefaultPM: shouldSetAsDefaultPM
        )
    }

    func createTestRadarOptions() -> STPRadarOptions {
        return STPRadarOptions(hcaptchaToken: "test_hcaptcha_token")
    }

    func createTestMandateData() -> STPMandateDataParams {
        return STPMandateDataParams.makeWithInferredValues()
    }

    // MARK: - Basic Configuration Tests

    func testCreateConfirmationTokenParams_basicConfiguration() {
        let intentConfig = createTestIntentConfig(mode: .payment(amount: 100, currency: "USD"))
        let confirmType = createTestSavedConfirmType()

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            elementsSession: nil
        )

        XCTAssertNotNil(params)
        XCTAssertEqual(params.returnURL, configuration.returnURL)
    }

    func testCreateConfirmationTokenParams_withShippingDetails() {
        let intentConfig = createTestIntentConfig(mode: .payment(amount: 100, currency: "USD"))
        let confirmType = createTestSavedConfirmType()

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            elementsSession: nil
        )

        XCTAssertNotNil(params.shipping)
        XCTAssertEqual(params.shipping?.name, "Jane Doe")
        XCTAssertEqual(params.shipping?.phone, "5551234567")
        XCTAssertEqual(params.shipping?.address.country, "US")
        XCTAssertEqual(params.shipping?.address.line1, "Line 1")
    }

    func testCreateConfirmationTokenParams_withoutShipping() {
        let intentConfig = createTestIntentConfig(mode: .payment(amount: 100, currency: "USD"))
        let confirmType = createTestSavedConfirmType()

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configurationWithoutShipping,
            intentConfig: intentConfig,
            elementsSession: nil
        )

        XCTAssertNil(params.shipping)
    }

    // MARK: - Payment Method Configuration Tests

    func testCreateConfirmationTokenParams_savedPaymentMethod() {
        let intentConfig = createTestIntentConfig(mode: .payment(amount: 100, currency: "USD"))
        let paymentMethod = createTestSavedPaymentMethod()
        let paymentOptions = STPConfirmPaymentMethodOptions()
        let clientAttributionMetadata = STPClientAttributionMetadata()

        let confirmType = PaymentSheet.ConfirmPaymentMethodType.saved(
            paymentMethod,
            paymentOptions: paymentOptions,
            clientAttributionMetadata: clientAttributionMetadata
        )

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            elementsSession: nil
        )

        XCTAssertEqual(params.paymentMethod, paymentMethod.stripeId)
        XCTAssertEqual(params.paymentMethodOptions, paymentOptions)
        XCTAssertEqual(params.clientAttributionMetadata, clientAttributionMetadata)
        XCTAssertNil(params.paymentMethodData)
    }

    func testCreateConfirmationTokenParams_newPaymentMethod() {
        let intentConfig = createTestIntentConfig(mode: .payment(amount: 100, currency: "USD"))
        let paymentMethodParams = createTestPaymentMethodParams()
        let paymentOptions = STPConfirmPaymentMethodOptions()
        let radarOptions = createTestRadarOptions()

        let confirmType = PaymentSheet.ConfirmPaymentMethodType.new(
            params: paymentMethodParams,
            paymentOptions: paymentOptions,
            paymentMethod: nil,
            shouldSave: false,
            shouldSetAsDefaultPM: false
        )

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            elementsSession: nil,
            radarOptions: radarOptions
        )

        XCTAssertEqual(params.paymentMethodData, paymentMethodParams)
        XCTAssertEqual(params.paymentMethodOptions, paymentOptions)
        XCTAssertEqual(params.paymentMethodData?.radarOptions, radarOptions)
        XCTAssertNil(params.paymentMethod)
        XCTAssertNil(params.setAsDefaultPM)
    }

    func testCreateConfirmationTokenParams_setAsDefaultPM_whenAllowed() {
        let intentConfig = createTestIntentConfig(mode: .payment(amount: 100, currency: "USD"))
        let confirmType = createTestNewConfirmType(shouldSave: false, shouldSetAsDefaultPM: true)

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            allowsSetAsDefaultPM: true,
            elementsSession: nil
        )

        XCTAssertEqual(params.setAsDefaultPM, NSNumber(value: true))
    }

    func testCreateConfirmationTokenParams_setAsDefaultPM_whenNotAllowed() {
        let intentConfig = createTestIntentConfig(mode: .payment(amount: 100, currency: "USD"))
        let confirmType = createTestNewConfirmType(shouldSave: false, shouldSetAsDefaultPM: true)

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            allowsSetAsDefaultPM: false,
            elementsSession: nil
        )

        XCTAssertNil(params.setAsDefaultPM)
    }

    func testCreateConfirmationTokenParams_setAsDefaultPM_whenNotRequested() {
        let intentConfig = createTestIntentConfig(mode: .payment(amount: 100, currency: "USD"))
        let confirmType = createTestNewConfirmType(shouldSave: false, shouldSetAsDefaultPM: false)

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            allowsSetAsDefaultPM: true,
            elementsSession: nil
        )

        XCTAssertNil(params.setAsDefaultPM)
    }

    // MARK: - Setup Future Usage Tests

    func testCreateConfirmationTokenParams_setupIntent_SFU() {
        let intentConfig = createTestIntentConfig(mode: .setup(currency: "USD", setupFutureUsage: .offSession))
        let confirmType = createTestSavedConfirmType()

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            elementsSession: nil
        )

        XCTAssertEqual(params.setupFutureUsage, .offSession)
    }

    func testCreateConfirmationTokenParams_paymentIntent_userSaves() {
        let intentConfig = createTestIntentConfig(mode: .payment(amount: 100, currency: "USD"))
        let confirmType = createTestNewConfirmType(shouldSave: true)

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            elementsSession: nil
        )

        XCTAssertEqual(params.setupFutureUsage, .offSession)
    }

    func testCreateConfirmationTokenParams_paymentIntent_topLevelSFU() {
        let intentConfig = createTestIntentConfig(mode: .payment(amount: 100, currency: "USD", setupFutureUsage: .onSession))
        let confirmType = createTestNewConfirmType(shouldSave: false)

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            elementsSession: nil
        )

        XCTAssertEqual(params.setupFutureUsage, .onSession)
    }

    func testCreateConfirmationTokenParams_paymentIntent_noSFU() {
        let intentConfig = createTestIntentConfig(mode: .payment(amount: 100, currency: "USD"))
        let confirmType = createTestNewConfirmType(shouldSave: false)

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            elementsSession: nil
        )

        XCTAssertEqual(params.setupFutureUsage, .none)
    }

    func testCreateConfirmationTokenParams_paymentIntent_PMOSFUFallbackToUserChoice() {
        // When no PMO SFU is set for the payment method type, should fall back to user choice
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 100,
                currency: "USD",
                paymentMethodOptions: .init(setupFutureUsageValues: [.payPal: .offSession]) // Different PM type
            )
        ) { _, _ in return "pi_test_123_secret_abc" }

        let confirmType = createTestNewConfirmType(shouldSave: true) // User wants to save card

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            elementsSession: nil
        )

        // No PMO SFU for .card, so should use user choice (.offSession when saving)
        XCTAssertEqual(params.setupFutureUsage, .offSession)
    }

    // MARK: - Setup Future Usage Priority Tests

    func testCreateConfirmationTokenParams_priorityOrder_userCheckboxBeatsPMOSFU() {
        // Priority: user checkbox > PMO SFU > top-level SFU
        // User saves (shouldSave=true) + PMO SFU=none → expects .offSession (user wins)
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 100,
                currency: "USD",
                setupFutureUsage: .onSession, // Top-level SFU
                paymentMethodOptions: .init(setupFutureUsageValues: [.card: .none]) // PMO SFU=none
            )
        ) { _, _ in return "pi_test_123_secret_abc" }

        let confirmType = createTestNewConfirmType(shouldSave: true) // User checkbox beats PMO

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            elementsSession: nil
        )

        // User choice should win over PMO SFU
        XCTAssertEqual(params.setupFutureUsage, .offSession)
    }

    func testCreateConfirmationTokenParams_priorityOrder_PMOSFUBeatsTopLevel() {
        // Priority: user checkbox > PMO SFU > top-level SFU
        // No user save + PMO SFU=none + top-level=.offSession → expects .none (PMO wins over top-level)
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 100,
                currency: "USD",
                setupFutureUsage: .offSession, // Top-level SFU
                paymentMethodOptions: .init(setupFutureUsageValues: [.card: .none]) // PMO SFU should win
            )
        ) { _, _ in return "pi_test_123_secret_abc" }

        let confirmType = createTestNewConfirmType(shouldSave: false) // User doesn't save

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            elementsSession: nil
        )

        // PMO SFU should beat top-level SFU
        XCTAssertEqual(params.setupFutureUsage, .none)
    }

    // MARK: - Edge Case Tests

    func testCreateConfirmationTokenParams_edgeCase_nilPMOValues() {
        // Priority: user checkbox > PMO SFU > top-level SFU
        // Nil setupFutureUsageValues dictionary should fall through to top-level
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 100,
                currency: "USD",
                setupFutureUsage: .onSession,
                paymentMethodOptions: .init(setupFutureUsageValues: nil) // Nil PMO values
            )
        ) { _, _ in return "pi_test_123_secret_abc" }

        let confirmType = createTestNewConfirmType(shouldSave: false)

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            elementsSession: nil
        )

        // Should fall through to top-level SFU
        XCTAssertEqual(params.setupFutureUsage, .onSession)
    }

    func testCreateConfirmationTokenParams_edgeCase_differentPaymentMethodTypes() {
        // Priority: user checkbox > PMO SFU > top-level SFU
        // Different payment method types should use correct PMO keys
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 100,
                currency: "USD",
                setupFutureUsage: .onSession,
                paymentMethodOptions: .init(setupFutureUsageValues: [
                    .card: .none,      // Card should get none
                    .payPal: .offSession,  // PayPal should get offSession
                ])
            )
        ) { _, _ in return "pi_test_123_secret_abc" }

        // Test card payment method
        let cardConfirmType = createTestNewConfirmType(shouldSave: false)
        let cardParams = PaymentSheet.createConfirmationTokenParams(
            confirmType: cardConfirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            elementsSession: nil
        )
        XCTAssertEqual(cardParams.setupFutureUsage, .none)

        // Test PayPal payment method
        let payPalPaymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_test_paypal",
            "type": "paypal",
            "paypal": [:],
        ])!
        let payPalConfirmType = PaymentSheet.ConfirmPaymentMethodType.saved(
            payPalPaymentMethod,
            paymentOptions: nil,
            clientAttributionMetadata: nil
        )
        let payPalParams = PaymentSheet.createConfirmationTokenParams(
            confirmType: payPalConfirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            elementsSession: nil
        )
        XCTAssertEqual(payPalParams.setupFutureUsage, .offSession)
    }

    func testCreateConfirmationTokenParams_priorityOrder_userCheckboxBeatsAllPMOValues() {
        // Priority: user checkbox > PMO SFU > top-level SFU
        // User saves should beat PMO SFU regardless of PMO value (.offSession, .onSession, .none)
        let testCases: [(PaymentSheet.IntentConfiguration.SetupFutureUsage, String)] = [
            (.offSession, "offSession"),
            (.onSession, "onSession"),
            (.none, "none"),
        ]

        for (pmoValue, caseName) in testCases {
            let intentConfig = PaymentSheet.IntentConfiguration(
                mode: .payment(
                    amount: 100,
                    currency: "USD",
                    setupFutureUsage: PaymentSheet.IntentConfiguration.SetupFutureUsage.none, // Top-level different from PMO
                    paymentMethodOptions: .init(setupFutureUsageValues: [.card: pmoValue])
                )
            ) { _, _ in return "pi_test_123_secret_abc" }

            let confirmType = createTestNewConfirmType(shouldSave: true) // User wants to save

            let params = PaymentSheet.createConfirmationTokenParams(
                confirmType: confirmType,
                configuration: configuration,
                intentConfig: intentConfig,
                elementsSession: nil
            )

            // User choice should always win, regardless of PMO SFU value
            XCTAssertEqual(params.setupFutureUsage, .offSession, "Failed for PMO SFU: \(caseName)")
        }
    }

    func testCreateConfirmationTokenParams_mandateDataRespectsNewPriorityOrder() {
        // Mandate data generation should use effective SFU from new priority order
        // Test PayPal which requires mandate when SFU is .offSession

        let payPalPaymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_test_paypal",
            "type": "paypal",
            "paypal": [:],
        ])!
        let confirmType = PaymentSheet.ConfirmPaymentMethodType.saved(
            payPalPaymentMethod,
            paymentOptions: nil,
            clientAttributionMetadata: nil
        )

        // Test PMO SFU (.offSession) overrides top-level (.none) -> should generate mandate
        let pmoOverridesTopLevelConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 100,
                currency: "USD",
                setupFutureUsage: PaymentSheet.IntentConfiguration.SetupFutureUsage.none, // Top-level says no save
                paymentMethodOptions: .init(setupFutureUsageValues: [.payPal: .offSession]) // PMO says save
            )
        ) { _, _ in return "pi_test_123_secret_abc" }

        let savedPayPalParams = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: pmoOverridesTopLevelConfig,
            elementsSession: nil
        )
        XCTAssertNotNil(savedPayPalParams.mandateData, "PMO SFU .offSession should generate mandate for PayPal")

        // Test: No user save + no PMO + top-level (.none) -> should NOT generate mandate
        let topLevelOnlyConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 100,
                currency: "USD",
                setupFutureUsage: PaymentSheet.IntentConfiguration.SetupFutureUsage.none // Only top-level, no PMO
            )
        ) { _, _ in return "pi_test_123_secret_abc" }

        let noSaveParams = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: topLevelOnlyConfig,
            elementsSession: nil
        )
        XCTAssertNil(noSaveParams.mandateData, "Top-level SFU .none should not generate mandate for PayPal")
    }

    // MARK: - Mandate Data Tests

    func testCreateConfirmationTokenParams_explicitMandateData() {
        let intentConfig = createTestIntentConfig(mode: .payment(amount: 100, currency: "USD"))
        let confirmType = createTestSavedConfirmType()
        let mandateData = createTestMandateData()

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            elementsSession: nil,
            mandateData: mandateData
        )

        XCTAssertEqual(params.mandateData, mandateData)
    }

    func testCreateConfirmationTokenParams_autoGeneratedMandate_payPal() {
        // Create a PayPal payment method for both tests
        let payPalPaymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_test_paypal",
            "type": "paypal",
            "paypal": [:],
        ])!
        let confirmType = PaymentSheet.ConfirmPaymentMethodType.saved(
            payPalPaymentMethod,
            paymentOptions: nil,
            clientAttributionMetadata: nil
        )

        // Test 1: Payment intent with PMO SFU
        let paymentIntentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 100,
                currency: "USD",
                paymentMethodOptions: .init(setupFutureUsageValues: [.payPal: .offSession])
            )
        ) { _, _ in return "pi_test_123_secret_abc" }

        let paymentParams = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: paymentIntentConfig,
            elementsSession: nil
        )
        XCTAssertNotNil(paymentParams.mandateData)

        // Test 2: Setup intent
        let setupIntentConfig = createTestIntentConfig(mode: .setup(currency: "USD", setupFutureUsage: .offSession))
        let setupParams = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: setupIntentConfig,
            elementsSession: nil
        )
        XCTAssertNotNil(setupParams.mandateData)
    }

    func testCreateConfirmationTokenParams_autoGeneratedMandate_usBankAccount() {
        let intentConfig = createTestIntentConfig(mode: .payment(amount: 100, currency: "USD"))

        // Create a US Bank Account payment method
        let usBankPaymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_test_us_bank",
            "type": "us_bank_account",
            "us_bank_account": [
                "account_type": "checking",
                "account_holder_type": "individual",
                "last4": "6789",
                "routing_number": "110000000",
            ],
        ])!

        let confirmType = PaymentSheet.ConfirmPaymentMethodType.saved(
            usBankPaymentMethod,
            paymentOptions: nil,
            clientAttributionMetadata: nil
        )

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            elementsSession: nil
        )

        XCTAssertNotNil(params.mandateData)
    }

    func testCreateConfirmationTokenParams_noMandateRequired_card() {
        let intentConfig = createTestIntentConfig(mode: .payment(amount: 100, currency: "USD"))
        let confirmType = createTestSavedConfirmType() // Creates a card payment method

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            elementsSession: nil
        )

        XCTAssertNil(params.mandateData)
    }

    func testCreateConfirmationTokenParams_noMandateRequired_payPal_withoutSFU() {
        let intentConfig = createTestIntentConfig(mode: .payment(amount: 100, currency: "USD"))

        // Create a PayPal payment method without SFU
        let payPalPaymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_test_paypal",
            "type": "paypal",
            "paypal": [:],
        ])!

        let confirmType = PaymentSheet.ConfirmPaymentMethodType.saved(
            payPalPaymentMethod,
            paymentOptions: nil,
            clientAttributionMetadata: nil
        )

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            elementsSession: nil
        )

        // Should still get mandate data from fallback to STPPaymentIntentParams.mandateDataIfRequired
        XCTAssertNil(params.mandateData)
    }
}
