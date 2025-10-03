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
        var config = PaymentSheet.Configuration()
        config.apiClient = apiClient
        config.returnURL = "myapp://payment-complete"
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

        let intentConfig = createTestIntentConfig(mode: .payment(amount: 100, currency: "USD"))
        let confirmType = createTestSavedConfirmType()

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: config,
            intentConfig: intentConfig,
            elementsSession: nil
        )

        XCTAssertEqual(params.returnURL, "myapp://payment-complete")
        XCTAssertNotNil(params.clientContext)
        XCTAssertEqual(params.clientContext?.currency, "USD")
        XCTAssertNotNil(params.shipping)
        XCTAssertEqual(params.shipping?.name, "Jane Doe")
        XCTAssertEqual(params.shipping?.phone, "5551234567")
        XCTAssertEqual(params.shipping?.address.country, "US")
        XCTAssertEqual(params.shipping?.address.line1, "Line 1")
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
        let clientAttributionMetadata = STPClientAttributionMetadata()
        paymentMethodParams.clientAttributionMetadata = clientAttributionMetadata
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
        XCTAssertNotNil(params.clientAttributionMetadata)
        XCTAssertEqual(params.clientAttributionMetadata, clientAttributionMetadata)
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

    // MARK: - Setup Future Usage Tests

    func testCreateConfirmationTokenParams_setupIntent_withSFU() {
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

    func testCreateConfirmationTokenParams_paymentIntent_withTopLevelSFU() {
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

        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 100,
                currency: "USD",
                paymentMethodOptions: .init(setupFutureUsageValues: [.payPal: .offSession])
            )
        ) { _, _ in return "pi_test_123_secret_abc" }

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            elementsSession: nil
        )

        XCTAssertNotNil(params.mandateData)
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

    func testCreateConfirmationTokenParams_cardWithoutSFU_noMandate() {
        let intentConfig = createTestIntentConfig(mode: .payment(amount: 100, currency: "USD"))
        let confirmType = createTestSavedConfirmType()

        let params = PaymentSheet.createConfirmationTokenParams(
            confirmType: confirmType,
            configuration: configuration,
            intentConfig: intentConfig,
            elementsSession: nil
        )

        XCTAssertNil(params.mandateData)
    }
}
