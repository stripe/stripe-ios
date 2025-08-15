//
//  STPApplePayContext+PaymentSheetTest.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 8/2/23.
//

@testable import StripeApplePay
@_spi(STP) import StripeCore
@testable @_spi(PaymentMethodOptionsSetupFutureUsagePreview) @_spi(SharedPaymentToken) import StripePaymentSheet
@testable import StripePaymentsTestUtils
import XCTest

final class STPApplePayContext_PaymentSheetTest: XCTestCase {
    let dummyDeferredConfirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = { _, _, _ in /* no-op */ }
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
