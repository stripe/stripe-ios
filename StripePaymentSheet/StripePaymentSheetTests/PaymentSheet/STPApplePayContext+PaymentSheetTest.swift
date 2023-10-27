//
//  STPApplePayContext+PaymentSheetTest.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 8/2/23.
//

@testable import StripeApplePay
@testable import StripePaymentSheet
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
        let intent = Intent.paymentIntent(STPFixtures.paymentIntent())
        let deferredIntent = Intent.deferredIntent(elementsSession: ._testCardValue(), intentConfig: .init(mode: .payment(amount: 2345, currency: "USD"), confirmHandler: dummyDeferredConfirmHandler))
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
        let intent = Intent.paymentIntent(STPFixtures.paymentIntent(paymentMethodTypes: ["card"], setupFutureUsage: .offSession))
        let deferredIntent = Intent.deferredIntent(elementsSession: ._testCardValue(), intentConfig: .init(mode: .payment(amount: 10, currency: "USD", setupFutureUsage: .offSession), confirmHandler: dummyDeferredConfirmHandler))
        for intent in [intent, deferredIntent] {
            let sut = STPApplePayContext.createPaymentRequest(intent: intent, configuration: configuration, applePay: applePayConfiguration)
            XCTAssertEqual(sut.paymentSummaryItems[0].amount, 0.1)
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

    func testCreatePaymentRequest_SetupIntent() {
        let intent = Intent.setupIntent(STPFixtures.setupIntent())
        let deferredIntent = Intent.deferredIntent(elementsSession: ._testCardValue(), intentConfig: .init(mode: .setup(currency: "USD"), confirmHandler: dummyDeferredConfirmHandler))
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
