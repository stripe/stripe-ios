//
//  PaymentSheetDeferredValidatorTests.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 5/16/23.
//

@testable@_spi(STP) import StripePaymentSheet
import XCTest

final class PaymentSheetDeferredValidatorTests: XCTestCase {
    let confirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = { _, _, _ in }

    func testMismatchedIntentAndIntentConfiguration() throws {
        let pi = STPFixtures.makePaymentIntent()
        let intentConfig_si = PaymentSheet.IntentConfiguration(mode: .setup(currency: "USD"), confirmHandler: confirmHandler)
        XCTAssertThrowsError(try PaymentSheetDeferredValidator.validate(paymentIntent: pi,
                                                                        intentConfiguration: intentConfig_si,
                                                                        isFlowController: false)) { error in
            XCTAssertEqual("\(error)", "An error occurred in PaymentSheet. You returned a PaymentIntent client secret but used a PaymentSheet.IntentConfiguration in setup mode.")
        }
        let si = STPFixtures.makeSetupIntent()
        let intentConfig_pi = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1080, currency: "USD"), confirmHandler: confirmHandler)
        XCTAssertThrowsError(try PaymentSheetDeferredValidator.validate(setupIntent: si, intentConfiguration: intentConfig_pi)) { error in
            XCTAssertEqual("\(error)", "An error occurred in PaymentSheet. You returned a SetupIntent client secret but used a PaymentSheet.IntentConfiguration in payment mode.")
        }
    }

    func testPaymentIntentMismatchedCurrency() throws {
        let pi = STPFixtures.makePaymentIntent(amount: 100, currency: "GBP")
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD"), confirmHandler: confirmHandler)
        XCTAssertThrowsError(try PaymentSheetDeferredValidator.validate(paymentIntent: pi,
                                                                        intentConfiguration: intentConfig,
                                                                        isFlowController: false)) { error in
            XCTAssertEqual("\(error)", "An error occurred in PaymentSheet. Your PaymentIntent currency (GBP) does not match the PaymentSheet.IntentConfiguration currency (USD).")
        }
    }

    func testPaymentIntentMismatchedSetupFutureUsage() throws {
        let pi = STPFixtures.makePaymentIntent(amount: 100, currency: "USD", setupFutureUsage: .offSession)
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD"), confirmHandler: confirmHandler)
        XCTAssertThrowsError(try PaymentSheetDeferredValidator.validate(paymentIntent: pi,
                                                                        intentConfiguration: intentConfig,
                                                                        isFlowController: false)) { error in
            XCTAssertEqual("\(error)", "An error occurred in PaymentSheet. Your PaymentIntent setupFutureUsage (offSession) does not match the PaymentSheet.IntentConfiguration setupFutureUsage (nil).")
        }
    }

    func testPaymentIntentMismatchedCaptureMethod() throws {
        let pi = STPFixtures.makePaymentIntent(amount: 100, currency: "USD", captureMethod: "manual")
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD", captureMethod: .automatic), confirmHandler: confirmHandler)
        XCTAssertThrowsError(try PaymentSheetDeferredValidator.validate(paymentIntent: pi,
                                                                        intentConfiguration: intentConfig,
                                                                        isFlowController: false)) { error in
            XCTAssertEqual("\(error)", "An error occurred in PaymentSheet. Your PaymentIntent captureMethod (manual) does not match the PaymentSheet.IntentConfiguration amount (automatic).")
        }
    }

    func testPaymentIntentNotFlowControllerManualConfirmationMethod() throws {
         let pi = STPFixtures.makePaymentIntent(amount: 1000, currency: "USD", confirmationMethod: "manual")
         let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD"), confirmHandler: confirmHandler)
        XCTAssertThrowsError(try PaymentSheetDeferredValidator.validate(paymentIntent: pi,
                                                                        intentConfiguration: intentConfig,
                                                                        isFlowController: false)) { error in
             XCTAssertEqual("\(error)", "An error occurred in PaymentSheet. Your PaymentIntent confirmationMethod (manual) can only be used with PaymentSheet.FlowController.")
         }
     }

    func testSetupIntentMismatchedUsage() throws {
        let si = STPFixtures.makeSetupIntent(usage: "on_session")
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .setup(currency: "USD", setupFutureUsage: .offSession), confirmHandler: confirmHandler)
        XCTAssertThrowsError(try PaymentSheetDeferredValidator.validate(setupIntent: si, intentConfiguration: intentConfig)) { error in
            XCTAssertEqual("\(error)", "An error occurred in PaymentSheet. Your SetupIntent usage (onSession) does not match the PaymentSheet.IntentConfiguration setupFutureUsage (offSession).")
        }
    }
}
