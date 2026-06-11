//
//  STPApplePayContext+PaymentSheetTest.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 8/2/23.
//

@testable import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@testable @_spi(STP) @_spi(PaymentMethodOptionsSetupFutureUsagePreview) @_spi(SharedPaymentToken) @_spi(CardFundingFilteringPrivatePreview) import StripePaymentSheet
@testable import StripePaymentsTestUtils
import XCTest

@MainActor
final class STPApplePayContext_PaymentSheetTest: XCTestCase {
    let dummyDeferredConfirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = { _, _ in return "" /* no-op */ }
    let dummyConfirmationTokenConfirmHandler: PaymentSheet.IntentConfiguration.ConfirmationTokenConfirmHandler = { _ in return "" }
    let applePayConfiguration = PaymentSheet.ApplePayConfiguration(merchantId: "merchant_id", merchantCountryCode: "GB")
    lazy var configuration: PaymentSheet.Configuration = {
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.applePay = applePayConfiguration
        return config
    }()

    func testCreatePaymentRequest_PaymentIntent() {
        let intent = Intent._testValue()
        let deferredIntent = Intent.deferredIntent(intentConfig: .init(mode: .payment(amount: 2345, currency: "USD"), confirmHandler: dummyDeferredConfirmHandler))
        for intent in [intent, deferredIntent] {
            let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: configuration, applePay: applePayConfiguration)
            XCTAssertEqual(sut.paymentSummaryItems[0].amount, 23.45)
            XCTAssertEqual(sut.paymentSummaryItems[0].type, .final)
            XCTAssertEqual(sut.currencyCode, "USD")
            XCTAssertEqual(sut.merchantIdentifier, "merchant_id")
            XCTAssertEqual(sut.countryCode, "GB")
#if compiler(>=5.9)
            if #available(macOS 14.0, iOS 17.0, *) {
                XCTAssertEqual(sut.applePayLaterAvailability, .available)
            }
#endif
        }
    }

    func testCreatePaymentRequest_PaymentIntentWithSetupFutureUsage() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card], setupFutureUsage: .offSession)
        let deferredIntent = Intent.deferredIntent(intentConfig: .init(mode: .payment(amount: 2345, currency: "USD", setupFutureUsage: .offSession), confirmHandler: dummyDeferredConfirmHandler))
        for intent in [intent, deferredIntent] {
            let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: configuration, applePay: applePayConfiguration)
            XCTAssertEqual(sut.paymentSummaryItems[0].amount, 23.45)
            XCTAssertEqual(sut.paymentSummaryItems[0].type, .final)
            XCTAssertEqual(sut.currencyCode, "USD")
            XCTAssertEqual(sut.merchantIdentifier, "merchant_id")
            XCTAssertEqual(sut.countryCode, "GB")
#if compiler(>=5.9)
            if #available(macOS 14.0, iOS 17.0, *) {
                XCTAssertEqual(sut.applePayLaterAvailability, .unavailable(.recurringTransaction))
            }
#endif
        }
    }

    func testCreatePaymentRequest_PaymentIntentWithPMOSetupFutureUsage() {
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.applePay = applePayConfiguration
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card], paymentMethodOptionsSetupFutureUsage: [.card: "off_session"])
        let deferredIntent = Intent.deferredIntent(intentConfig: .init(mode: .payment(amount: 2345, currency: "USD", paymentMethodOptions: PaymentSheet.IntentConfiguration.Mode.PaymentMethodOptions(setupFutureUsageValues: [.card: .offSession])), confirmHandler: dummyDeferredConfirmHandler))
        for intent in [intent, deferredIntent] {
            let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: config, applePay: applePayConfiguration)
            XCTAssertEqual(sut.paymentSummaryItems[0].amount, 23.45)
            XCTAssertEqual(sut.paymentSummaryItems[0].type, .final)
            XCTAssertEqual(sut.currencyCode, "USD")
            XCTAssertEqual(sut.merchantIdentifier, "merchant_id")
            XCTAssertEqual(sut.countryCode, "GB")
#if compiler(>=5.9)
            if #available(macOS 14.0, iOS 17.0, *) {
                XCTAssertEqual(sut.applePayLaterAvailability, .unavailable(.recurringTransaction))
            }
#endif
        }
    }

    func testCreatePaymentRequest_PaymentIntentWithTopLevelSetupFutureUsagePMOSetupFutureUsageNone() {
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.applePay = applePayConfiguration
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card], setupFutureUsage: .offSession, paymentMethodOptionsSetupFutureUsage: [.card: "none"])
        let deferredIntent = Intent.deferredIntent(intentConfig: .init(mode: .payment(amount: 2345, currency: "USD", setupFutureUsage: .offSession, paymentMethodOptions: PaymentSheet.IntentConfiguration.Mode.PaymentMethodOptions(setupFutureUsageValues: [.card: .none])), confirmHandler: dummyDeferredConfirmHandler))
        for intent in [intent, deferredIntent] {
            let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: config, applePay: applePayConfiguration)
            XCTAssertEqual(sut.paymentSummaryItems[0].amount, 23.45)
            XCTAssertEqual(sut.paymentSummaryItems[0].type, .final)
            XCTAssertEqual(sut.currencyCode, "USD")
            XCTAssertEqual(sut.merchantIdentifier, "merchant_id")
            XCTAssertEqual(sut.countryCode, "GB")
#if compiler(>=5.9)
            if #available(macOS 14.0, iOS 17.0, *) {
                XCTAssertEqual(sut.applePayLaterAvailability, .available)
            }
#endif
        }
    }

    func testCreatePaymentRequest_SetupIntent() {
        let intent = Intent.setupIntent(STPFixtures.setupIntent())
        let deferredIntent = Intent.deferredIntent(intentConfig: .init(mode: .setup(currency: "USD"), confirmHandler: dummyDeferredConfirmHandler))
        for intent in [intent, deferredIntent] {
            let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: configuration, applePay: applePayConfiguration)
            XCTAssertEqual(sut.paymentSummaryItems[0].amount, .zero)
            XCTAssertEqual(sut.paymentSummaryItems[0].type, .pending)
            XCTAssertEqual(sut.currencyCode, "USD")
            XCTAssertEqual(sut.merchantIdentifier, "merchant_id")
            XCTAssertEqual(sut.countryCode, "GB")
#if compiler(>=5.9)
            if #available(macOS 14.0, iOS 17.0, *) {
                XCTAssertEqual(sut.applePayLaterAvailability, .unavailable(.recurringTransaction))
            }
#endif
        }
    }

    func testCreatePaymentRequest_brandAcceptance_all() {
        var configuration = configuration
        configuration.cardBrandAcceptance = .all
        let intent = Intent._testValue()
        let deferredIntent = Intent.deferredIntent(intentConfig: .init(mode: .payment(amount: 2345, currency: "USD"), confirmHandler: dummyDeferredConfirmHandler))
        for intent in [intent, deferredIntent] {
            let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: configuration, applePay: applePayConfiguration)
            XCTAssertEqual(sut.paymentSummaryItems[0].amount, 23.45)
            XCTAssertEqual(sut.paymentSummaryItems[0].type, .final)
            XCTAssertEqual(sut.currencyCode, "USD")
            XCTAssertEqual(sut.merchantIdentifier, "merchant_id")
            XCTAssertEqual(sut.countryCode, "GB")
            XCTAssertEqual(sut.supportedNetworks, StripeAPI.supportedPKPaymentNetworks())
            if #available(macOS 14.0, iOS 17.0, *) {
                XCTAssertEqual(sut.applePayLaterAvailability, .available)
            }
            }
        }

    func testCreatePaymentRequest_brandAcceptance_disallowedBrands() {
        var configuration = configuration
        configuration.cardBrandAcceptance = .disallowed(brands: [.amex, .visa])
        let intent = Intent._testValue()
        let deferredIntent = Intent.deferredIntent(intentConfig: .init(mode: .payment(amount: 2345, currency: "USD"), confirmHandler: dummyDeferredConfirmHandler))
        for intent in [intent, deferredIntent] {
            let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: configuration, applePay: applePayConfiguration)
            XCTAssertEqual(sut.paymentSummaryItems[0].amount, 23.45)
            XCTAssertEqual(sut.paymentSummaryItems[0].type, .final)
            XCTAssertEqual(sut.currencyCode, "USD")
            XCTAssertEqual(sut.merchantIdentifier, "merchant_id")
            XCTAssertEqual(sut.countryCode, "GB")
            XCTAssertEqual(sut.supportedNetworks, [.masterCard, .maestro, .discover])
            if #available(macOS 14.0, iOS 17.0, *) {
                XCTAssertEqual(sut.applePayLaterAvailability, .unavailable(.recurringTransaction))
            }
            }
        }

    func testCreatePaymentRequest_brandAcceptance_allowedBrands() {
        var configuration = configuration
        configuration.cardBrandAcceptance = .allowed(brands: [.visa])
        let intent = Intent._testValue()
        let deferredIntent = Intent.deferredIntent(intentConfig: .init(mode: .payment(amount: 2345, currency: "USD"), confirmHandler: dummyDeferredConfirmHandler))
        for intent in [intent, deferredIntent] {
            let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: configuration, applePay: applePayConfiguration)
            XCTAssertEqual(sut.paymentSummaryItems[0].amount, 23.45)
            XCTAssertEqual(sut.paymentSummaryItems[0].type, .final)
            XCTAssertEqual(sut.currencyCode, "USD")
            XCTAssertEqual(sut.merchantIdentifier, "merchant_id")
            XCTAssertEqual(sut.countryCode, "GB")
            XCTAssertEqual(sut.supportedNetworks, [.visa])
            if #available(macOS 14.0, iOS 17.0, *) {
                XCTAssertEqual(sut.applePayLaterAvailability, .unavailable(.recurringTransaction))
            }
        }
    }

    // MARK: - Card Funding Acceptance Tests

    func testCreatePaymentRequest_fundingAcceptance_all() {
        // Don't set allowedCardFundingTypes - default accepts all funding types
        let intent = Intent._testValue()
        let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: configuration, applePay: applePayConfiguration)
        // When all funding types are accepted, the default merchant capabilities from StripeAPI.paymentRequest are preserved (.capability3DS)
        XCTAssertEqual(sut.merchantCapabilities, .capability3DS)
    }

    func testCreatePaymentRequest_fundingAcceptance_debitOnly() {
        let intent = Intent._testValue()
        let cardFundingFilter = CardFundingFilter(allowedFundingTypes: .debit, filteringEnabled: true)
        let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: configuration, applePay: applePayConfiguration, cardFundingFilter: cardFundingFilter)
        XCTAssertTrue(sut.merchantCapabilities.contains(.capability3DS))
        XCTAssertTrue(sut.merchantCapabilities.contains(.capabilityDebit))
        XCTAssertFalse(sut.merchantCapabilities.contains(.capabilityCredit))
    }

    func testCreatePaymentRequest_fundingAcceptance_creditOnly() {
        let intent = Intent._testValue()
        let cardFundingFilter = CardFundingFilter(allowedFundingTypes: .credit, filteringEnabled: true)
        let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: configuration, applePay: applePayConfiguration, cardFundingFilter: cardFundingFilter)
        XCTAssertTrue(sut.merchantCapabilities.contains(.capability3DS))
        XCTAssertFalse(sut.merchantCapabilities.contains(.capabilityDebit))
        XCTAssertTrue(sut.merchantCapabilities.contains(.capabilityCredit))
    }

    func testCreatePaymentRequest_fundingAcceptance_debitAndCredit() {
        let intent = Intent._testValue()
        let cardFundingFilter = CardFundingFilter(allowedFundingTypes: [.debit, .credit], filteringEnabled: true)
        let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: configuration, applePay: applePayConfiguration, cardFundingFilter: cardFundingFilter)
        XCTAssertTrue(sut.merchantCapabilities.contains(.capability3DS))
        XCTAssertTrue(sut.merchantCapabilities.contains(.capabilityDebit))
        XCTAssertTrue(sut.merchantCapabilities.contains(.capabilityCredit))
    }

    func testCreatePaymentRequest_fundingAcceptance_filteringDisabled() {
        // Even with restrictive funding types, if filtering is disabled, capabilities should not be modified
        let intent = Intent._testValue()
        let cardFundingFilter = CardFundingFilter(allowedFundingTypes: .debit, filteringEnabled: false)
        let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: configuration, applePay: applePayConfiguration, cardFundingFilter: cardFundingFilter)
        // When filtering is disabled, the default merchant capabilities from StripeAPI.paymentRequest are preserved (.capability3DS)
        XCTAssertEqual(sut.merchantCapabilities, .capability3DS)
    }

    func testCreatePaymentRequest_requiredContactFields_billingOnly() {
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.applePay = applePayConfiguration
        config.billingDetailsCollectionConfiguration.name = .always
        config.billingDetailsCollectionConfiguration.address = .full
        config.billingDetailsCollectionConfiguration.email = .never
        config.billingDetailsCollectionConfiguration.phone = .never

        let intent = Intent._testValue()
        let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: config, applePay: applePayConfiguration)

        XCTAssertTrue(sut.requiredBillingContactFields.contains(.name))
        XCTAssertTrue(sut.requiredBillingContactFields.contains(.postalAddress))
        XCTAssertFalse(sut.requiredBillingContactFields.contains(.emailAddress))
        XCTAssertFalse(sut.requiredBillingContactFields.contains(.phoneNumber))
        XCTAssertTrue(sut.requiredShippingContactFields.isEmpty)
    }

    func testCreatePaymentRequest_requiredContactFields_phoneAndEmailToShipping() {
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.applePay = applePayConfiguration
        config.billingDetailsCollectionConfiguration.name = .always
        config.billingDetailsCollectionConfiguration.address = .full
        config.billingDetailsCollectionConfiguration.email = .always
        config.billingDetailsCollectionConfiguration.phone = .always

        let intent = Intent._testValue()
        let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: config, applePay: applePayConfiguration)

        // Billing should only have name and address
        XCTAssertTrue(sut.requiredBillingContactFields.contains(.name))
        XCTAssertTrue(sut.requiredBillingContactFields.contains(.postalAddress))
        XCTAssertFalse(sut.requiredBillingContactFields.contains(.emailAddress))
        XCTAssertFalse(sut.requiredBillingContactFields.contains(.phoneNumber))

        // Phone and email should go to shipping
        XCTAssertTrue(sut.requiredShippingContactFields.contains(.emailAddress))
        XCTAssertTrue(sut.requiredShippingContactFields.contains(.phoneNumber))
    }

    func testCreatePaymentRequest_requiredContactFields_emailOnly() {
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.applePay = applePayConfiguration
        config.billingDetailsCollectionConfiguration.email = .always
        config.billingDetailsCollectionConfiguration.phone = .never

        let intent = Intent._testValue()
        let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: config, applePay: applePayConfiguration)

        XCTAssertFalse(sut.requiredBillingContactFields.contains(.emailAddress))
        XCTAssertFalse(sut.requiredBillingContactFields.contains(.phoneNumber))
        XCTAssertTrue(sut.requiredShippingContactFields.contains(.emailAddress))
        XCTAssertFalse(sut.requiredShippingContactFields.contains(.phoneNumber))
    }

    func testCreatePaymentRequest_requiredContactFields_phoneOnly() {
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.applePay = applePayConfiguration
        config.billingDetailsCollectionConfiguration.email = .never
        config.billingDetailsCollectionConfiguration.phone = .always

        let intent = Intent._testValue()
        let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: config, applePay: applePayConfiguration)

        XCTAssertFalse(sut.requiredBillingContactFields.contains(.emailAddress))
        XCTAssertFalse(sut.requiredBillingContactFields.contains(.phoneNumber))
        XCTAssertFalse(sut.requiredShippingContactFields.contains(.emailAddress))
        XCTAssertTrue(sut.requiredShippingContactFields.contains(.phoneNumber))
    }

    func testCreatePaymentRequest_label_normalIntent() {
        var configuration = configuration
        configuration.merchantDisplayName = "Merchant Name"
        let intent = Intent._testValue()
        let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: configuration, applePay: applePayConfiguration)
        XCTAssertEqual(sut.paymentSummaryItems[0].label, "Merchant Name")
    }

    func testCreatePaymentRequest_label_deferredIntentWithoutSellerDetails() {
        var configuration = configuration
        configuration.merchantDisplayName = "Merchant Name"
        let deferredIntent = Intent.deferredIntent(
            intentConfig: .init(
                mode: .payment(amount: 2345, currency: "USD"),
                confirmHandler: dummyDeferredConfirmHandler
            )
        )
        let sut = STPApplePayContext.createPaymentRequest(intent: deferredIntent, configuration: configuration, applePay: applePayConfiguration)
        XCTAssertEqual(sut.paymentSummaryItems[0].label, "Merchant Name")
    }

    func testCreatePaymentRequest_label_sptDeferredIntentWithoutSellerDetails() {
        var configuration = configuration
        configuration.merchantDisplayName = "Merchant Name"
        let deferredIntent = Intent.deferredIntent(
            intentConfig: .init(
                sharedPaymentTokenSessionWithMode: .payment(amount: 2345, currency: "USD"),
                sellerDetails: nil,
                preparePaymentMethodHandler: { _, _ in /* no-op */ }
            )
        )
        let sut = STPApplePayContext.createPaymentRequest(intent: deferredIntent, configuration: configuration, applePay: applePayConfiguration)
        XCTAssertEqual(sut.paymentSummaryItems[0].label, "Merchant Name")
    }

    func testCreatePaymentRequest_label_sptDeferredIntentWithSellerDetails() {
        var configuration = configuration
        configuration.merchantDisplayName = "Merchant Name"
        let deferredIntent = Intent.deferredIntent(
            intentConfig: .init(
                sharedPaymentTokenSessionWithMode: .payment(amount: 2345, currency: "USD"),
                sellerDetails: .init(
                    networkId: "networkID",
                    externalId: "externalID",
                    businessName: "Something different from the merchant name"
                ),
                preparePaymentMethodHandler: { _, _ in /* no-op */ }
            )
        )
        let sut = STPApplePayContext.createPaymentRequest(intent: deferredIntent, configuration: configuration, applePay: applePayConfiguration)
        XCTAssertEqual(sut.paymentSummaryItems[0].label, "Something different from the merchant name")
    }

    // MARK: - ConfirmationToken Tests

    func testCreatePaymentRequest_ConfirmationTokenDeferred() {
        // Test that confirmation token deferred intents create proper payment requests
        let confirmationTokenDeferredIntent = Intent.deferredIntent(
            intentConfig: .init(
                mode: .payment(amount: 2345, currency: "USD"),
                confirmationTokenConfirmHandler: dummyConfirmationTokenConfirmHandler
            )
        )

        let sut = STPApplePayContext.createPaymentRequest(intent: confirmationTokenDeferredIntent, configuration: configuration, applePay: applePayConfiguration)

        // Should create identical payment request as regular deferred intent
        XCTAssertEqual(sut.paymentSummaryItems[0].amount, 23.45)
        XCTAssertEqual(sut.paymentSummaryItems[0].type, .final)
        XCTAssertEqual(sut.currencyCode, "USD")
        XCTAssertEqual(sut.merchantIdentifier, "merchant_id")
        XCTAssertEqual(sut.countryCode, "GB")
    }

    func testCreatePaymentRequest_ConfirmationTokenSetup() {
        // Test that confirmation token setup intents work
        let confirmationTokenSetupIntent = Intent.deferredIntent(
            intentConfig: .init(
                mode: .setup(currency: "USD"),
                confirmationTokenConfirmHandler: dummyConfirmationTokenConfirmHandler
            )
        )

        let sut = STPApplePayContext.createPaymentRequest(intent: confirmationTokenSetupIntent, configuration: configuration, applePay: applePayConfiguration)

        // Should create setup intent payment request
        XCTAssertEqual(sut.paymentSummaryItems[0].amount, .zero)
        XCTAssertEqual(sut.paymentSummaryItems[0].type, .pending)
        XCTAssertEqual(sut.currencyCode, "USD")
        XCTAssertEqual(sut.merchantIdentifier, "merchant_id")
        XCTAssertEqual(sut.countryCode, "GB")
    }

    func testCreatePaymentRequest_ConfirmationTokenWithSetupFutureUsage() {
        // Test that confirmation token deferred intents with setup future usage work
        let confirmationTokenDeferredIntent = Intent.deferredIntent(
            intentConfig: .init(
                mode: .payment(amount: 2345, currency: "USD", setupFutureUsage: .offSession),
                confirmationTokenConfirmHandler: dummyConfirmationTokenConfirmHandler
            )
        )

        let sut = STPApplePayContext.createPaymentRequest(intent: confirmationTokenDeferredIntent, configuration: configuration, applePay: applePayConfiguration)

        // Should create payment request with setup future usage
        XCTAssertEqual(sut.paymentSummaryItems[0].amount, 23.45)
        XCTAssertEqual(sut.paymentSummaryItems[0].type, .final)
        XCTAssertEqual(sut.currencyCode, "USD")
        XCTAssertEqual(sut.merchantIdentifier, "merchant_id")
        XCTAssertEqual(sut.countryCode, "GB")
#if compiler(>=5.9)
        if #available(macOS 14.0, iOS 17.0, *) {
            XCTAssertEqual(sut.applePayLaterAvailability, .unavailable(.recurringTransaction))
        }
#endif
    }

    func testCreatePaymentRequest_ConfirmationTokenWithPMOSetupFutureUsage() {
        // Test that confirmation token deferred intents with PMO setup future usage work
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.applePay = applePayConfiguration

        let confirmationTokenDeferredIntent = Intent.deferredIntent(
            intentConfig: .init(
                mode: .payment(
                    amount: 2345,
                    currency: "USD",
                    paymentMethodOptions: PaymentSheet.IntentConfiguration.Mode.PaymentMethodOptions(
                        setupFutureUsageValues: [.card: .offSession]
                    )
                ),
                confirmationTokenConfirmHandler: dummyConfirmationTokenConfirmHandler
            )
        )

        let sut = STPApplePayContext.createPaymentRequest(intent: confirmationTokenDeferredIntent, configuration: config, applePay: applePayConfiguration)

        // Should create payment request with PMO setup future usage
        XCTAssertEqual(sut.paymentSummaryItems[0].amount, 23.45)
        XCTAssertEqual(sut.paymentSummaryItems[0].type, .final)
        XCTAssertEqual(sut.currencyCode, "USD")
        XCTAssertEqual(sut.merchantIdentifier, "merchant_id")
        XCTAssertEqual(sut.countryCode, "GB")
#if compiler(>=5.9)
        if #available(macOS 14.0, iOS 17.0, *) {
            XCTAssertEqual(sut.applePayLaterAvailability, .unavailable(.recurringTransaction))
        }
#endif
    }

    // MARK: - CheckoutSession Tests

    func testCreatePaymentRequest_CheckoutSession_PaymentMode() {
        let intent = Intent._testCheckoutSession(mode: .payment, amount: 2345, currency: "USD")
        let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: configuration, applePay: applePayConfiguration)
        XCTAssertEqual(sut.paymentSummaryItems[0].amount, 23.45)
        XCTAssertEqual(sut.paymentSummaryItems[0].type, .final)
        XCTAssertEqual(sut.currencyCode, "USD")
        XCTAssertEqual(sut.merchantIdentifier, "merchant_id")
        XCTAssertEqual(sut.countryCode, "GB")
#if compiler(>=5.9)
        if #available(macOS 14.0, iOS 17.0, *) {
            XCTAssertEqual(sut.applePayLaterAvailability, .available)
        }
#endif
    }

    func testCreatePaymentRequest_CheckoutSession_SetupMode() {
        let intent = Intent._testCheckoutSession(mode: .setup, amount: nil, currency: "USD")
        let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: configuration, applePay: applePayConfiguration)
        XCTAssertEqual(sut.paymentSummaryItems[0].amount, .zero)
        XCTAssertEqual(sut.paymentSummaryItems[0].type, .pending)
        XCTAssertEqual(sut.currencyCode, "USD")
        XCTAssertEqual(sut.merchantIdentifier, "merchant_id")
        XCTAssertEqual(sut.countryCode, "GB")
#if compiler(>=5.9)
        if #available(macOS 14.0, iOS 17.0, *) {
            XCTAssertEqual(sut.applePayLaterAvailability, .unavailable(.recurringTransaction))
        }
#endif
    }

    func testCreatePaymentRequest_CheckoutSession_SetupMode_WithZeroAmount() {
        // Real server returns total_summary with total: 0 for setup mode
        let intent = Intent._testCheckoutSession(mode: .setup, amount: 0, currency: "USD")
        let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: configuration, applePay: applePayConfiguration)
        XCTAssertEqual(sut.paymentSummaryItems[0].amount, .zero)
        XCTAssertEqual(sut.paymentSummaryItems[0].type, .pending)
        XCTAssertEqual(sut.currencyCode, "USD")
        XCTAssertEqual(sut.merchantIdentifier, "merchant_id")
        XCTAssertEqual(sut.countryCode, "GB")
#if compiler(>=5.9)
        if #available(macOS 14.0, iOS 17.0, *) {
            XCTAssertEqual(sut.applePayLaterAvailability, .unavailable(.recurringTransaction))
        }
#endif
    }

    // MARK: - CheckoutSession Line Items Tests

    private func makeMerchantConfiguration() -> PaymentSheet.Configuration {
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.merchantDisplayName = "Acme"
        config.applePay = applePayConfiguration
        return config
    }

    func testCreatePaymentRequest_CheckoutSession_SingleLineItem() {
        let lineItems: [Checkout.LineItem] = [
            .init(id: "li_1", name: "Widget", quantity: 1, unitAmount: .testValue(2345)),
        ]
        let intent = Intent._testCheckoutSession(
            mode: .payment,
            amount: 2345,
            currency: "USD",
            lineItems: lineItems
        )
        let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: makeMerchantConfiguration(), applePay: applePayConfiguration)

        XCTAssertEqual(sut.paymentSummaryItems.count, 2)
        XCTAssertEqual(sut.paymentSummaryItems[0].label, "Widget")
        XCTAssertEqual(sut.paymentSummaryItems[0].amount, NSDecimalNumber(string: "23.45"))
        XCTAssertEqual(sut.paymentSummaryItems[0].type, .final)
        XCTAssertEqual(sut.paymentSummaryItems[1].label, "Acme")
        XCTAssertEqual(sut.paymentSummaryItems[1].amount, NSDecimalNumber(string: "23.45"))
        XCTAssertEqual(sut.paymentSummaryItems[1].type, .final)
    }

    func testCreatePaymentRequest_CheckoutSession_MultipleLineItemsWithQuantity() {
        let lineItems: [Checkout.LineItem] = [
            .init(id: "li_1", name: "Widget", quantity: 3, unitAmount: .testValue(1000)),
            .init(id: "li_2", name: "Gadget", quantity: 1, unitAmount: .testValue(500)),
        ]
        let intent = Intent._testCheckoutSession(
            mode: .payment,
            amount: 3500,
            currency: "USD",
            lineItems: lineItems
        )
        let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: makeMerchantConfiguration(), applePay: applePayConfiguration)

        XCTAssertEqual(sut.paymentSummaryItems.count, 3)
        XCTAssertEqual(sut.paymentSummaryItems[0].label, String.Localized.lineItemLabel(name: "Widget", quantity: 3))
        XCTAssertEqual(sut.paymentSummaryItems[0].amount, NSDecimalNumber(string: "30.00"))
        XCTAssertEqual(sut.paymentSummaryItems[1].label, "Gadget")
        XCTAssertEqual(sut.paymentSummaryItems[1].amount, NSDecimalNumber(string: "5.00"))
        XCTAssertEqual(sut.paymentSummaryItems[2].label, "Acme")
        XCTAssertEqual(sut.paymentSummaryItems[2].amount, NSDecimalNumber(string: "35.00"))
        XCTAssertEqual(sut.paymentSummaryItems[2].type, .final)
    }

    func testCreatePaymentRequest_CheckoutSession_WithBreakdownRows() {
        let lineItems: [Checkout.LineItem] = [
            .init(id: "li_1", name: "Widget", quantity: 1, unitAmount: .testValue(2000)),
            .init(id: "li_2", name: "Gadget", quantity: 2, unitAmount: .testValue(500)),
        ]
        // subtotal = 3000, shipping = 500, tax = 200, discount = 100 -> total = 3600
        let intent = Intent._testCheckoutSession(
            mode: .payment,
            amount: 3600,
            currency: "USD",
            lineItems: lineItems,
            subtotal: 3000,
            shippingAmount: 500,
            taxAmount: 200,
            discountAmount: 100
        )
        let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: makeMerchantConfiguration(), applePay: applePayConfiguration)

        XCTAssertEqual(sut.paymentSummaryItems.count, 7)
        XCTAssertEqual(sut.paymentSummaryItems[0].label, "Widget")
        XCTAssertEqual(sut.paymentSummaryItems[0].amount, NSDecimalNumber(string: "20.00"))
        XCTAssertEqual(sut.paymentSummaryItems[1].label, String.Localized.lineItemLabel(name: "Gadget", quantity: 2))
        XCTAssertEqual(sut.paymentSummaryItems[1].amount, NSDecimalNumber(string: "10.00"))
        XCTAssertEqual(sut.paymentSummaryItems[2].label, String.Localized.subtotal)
        XCTAssertEqual(sut.paymentSummaryItems[2].amount, NSDecimalNumber(string: "30.00"))
        XCTAssertEqual(sut.paymentSummaryItems[3].label, String.Localized.shipping)
        XCTAssertEqual(sut.paymentSummaryItems[3].amount, NSDecimalNumber(string: "5.00"))
        XCTAssertEqual(sut.paymentSummaryItems[4].label, String.Localized.tax)
        XCTAssertEqual(sut.paymentSummaryItems[4].amount, NSDecimalNumber(string: "2.00"))
        XCTAssertEqual(sut.paymentSummaryItems[5].label, String.Localized.discount)
        XCTAssertEqual(sut.paymentSummaryItems[5].amount, NSDecimalNumber(string: "-1.00"))
        XCTAssertEqual(sut.paymentSummaryItems[6].label, "Acme")
        XCTAssertEqual(sut.paymentSummaryItems[6].amount, NSDecimalNumber(string: "36.00"))
        XCTAssertEqual(sut.paymentSummaryItems[6].type, .final)
    }

    func testCreatePaymentRequest_CheckoutSession_OmitsBreakdownWhenZero() {
        let lineItems: [Checkout.LineItem] = [
            .init(id: "li_1", name: "Widget", quantity: 1, unitAmount: .testValue(2345)),
        ]
        let intent = Intent._testCheckoutSession(
            mode: .payment,
            amount: 2345,
            currency: "USD",
            lineItems: lineItems,
            subtotal: 2345,
            shippingAmount: 0,
            taxAmount: 0,
            discountAmount: 0
        )
        let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: makeMerchantConfiguration(), applePay: applePayConfiguration)

        XCTAssertEqual(sut.paymentSummaryItems.count, 2)
        XCTAssertEqual(sut.paymentSummaryItems[0].label, "Widget")
        XCTAssertEqual(sut.paymentSummaryItems[1].label, "Acme")
    }

    func testCreatePaymentRequest_CheckoutSession_FallsBackWhenLineItemsEmpty() {
        let intent = Intent._testCheckoutSession(mode: .payment, amount: 2345, currency: "USD")
        let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: configuration, applePay: applePayConfiguration)
        XCTAssertEqual(sut.paymentSummaryItems.count, 1)
        XCTAssertEqual(sut.paymentSummaryItems[0].amount, NSDecimalNumber(string: "23.45"))
        XCTAssertEqual(sut.paymentSummaryItems[0].type, .final)
    }

    func testCreatePaymentRequest_CheckoutSession_MerchantPaymentSummaryItemsTakePrecedence() {
        let merchantItems: [PKPaymentSummaryItem] = [
            PKPaymentSummaryItem(label: "Custom", amount: NSDecimalNumber(string: "9.99"), type: .final),
        ]
        let applePay = PaymentSheet.ApplePayConfiguration(
            merchantId: "merchant_id",
            merchantCountryCode: "GB",
            paymentSummaryItems: merchantItems
        )

        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        config.applePay = applePay

        let lineItems: [Checkout.LineItem] = [
            .init(id: "li_1", name: "Widget", quantity: 1, unitAmount: .testValue(2345)),
        ]
        let intent = Intent._testCheckoutSession(
            mode: .payment,
            amount: 2345,
            currency: "USD",
            lineItems: lineItems
        )
        let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: config, applePay: applePay)

        XCTAssertEqual(sut.paymentSummaryItems.count, 1)
        XCTAssertEqual(sut.paymentSummaryItems[0].label, "Custom")
        XCTAssertEqual(sut.paymentSummaryItems[0].amount, NSDecimalNumber(string: "9.99"))
    }
}

#if compiler(>=5.9)
@available(macOS 14.0, iOS 17.0, *)
extension PKPaymentRequest.ApplePayLaterAvailability: Equatable {
    public static func == (lhs: PKPaymentRequest.ApplePayLaterAvailability, rhs: PKPaymentRequest.ApplePayLaterAvailability) -> Bool {
        switch (lhs, rhs) {
        case (.available, .available):
            return true
        case (.unavailable(.itemIneligible), .unavailable(.itemIneligible)):
            return true
        case (.unavailable(.recurringTransaction), .unavailable(.recurringTransaction)):
            return true
        default:
            return false
        }
    }
}
#endif
