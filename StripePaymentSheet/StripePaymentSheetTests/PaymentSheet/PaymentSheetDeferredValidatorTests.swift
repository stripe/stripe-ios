//
//  PaymentSheetDeferredValidatorTests.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 5/16/23.
//

@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripeCore
import XCTest

final class PaymentSheetDeferredValidatorTests: XCTestCase {
    let confirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = { _, _, _ in }
    
    func testMismatchedIntentAndIntentConfiguration() throws {
        let pi = STPFixtures.makePaymentIntent()
        let intentConfig_si = PaymentSheet.IntentConfiguration(mode: .setup(currency: "USD"), confirmHandler: confirmHandler)
        XCTAssertThrowsError(try PaymentSheetDeferredValidator.validate(paymentIntent: pi,
                                                                        intentConfiguration: intentConfig_si,
                                                                        paymentMethod: STPPaymentMethod._testCard(),
                                                                        isFlowController: false)) { error in
            XCTAssertEqual("\(error)", "An error occurred in PaymentSheet. You returned a PaymentIntent client secret but used a PaymentSheet.IntentConfiguration in setup mode.")
        }
        let si = STPFixtures.makeSetupIntent()
        let intentConfig_pi = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1080, currency: "USD"), confirmHandler: confirmHandler)
        XCTAssertThrowsError(try PaymentSheetDeferredValidator.validate(setupIntent: si, intentConfiguration: intentConfig_pi, paymentMethod: STPPaymentMethod._testCard())) { error in
            XCTAssertEqual("\(error)", "An error occurred in PaymentSheet. You returned a SetupIntent client secret but used a PaymentSheet.IntentConfiguration in payment mode.")
        }
    }
    
    func testPaymentIntentMismatchedCurrency() throws {
        let pi = STPFixtures.makePaymentIntent(amount: 100, currency: "GBP")
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD"), confirmHandler: confirmHandler)
        XCTAssertThrowsError(try PaymentSheetDeferredValidator.validate(paymentIntent: pi,
                                                                        intentConfiguration: intentConfig,
                                                                        paymentMethod: STPPaymentMethod._testCard(),
                                                                        isFlowController: false)) { error in
            XCTAssertEqual("\(error)", "An error occurred in PaymentSheet. Your PaymentIntent currency (GBP) does not match the PaymentSheet.IntentConfiguration currency (USD).")
        }
    }
    
    func testPaymentIntentMismatchedSetupFutureUsage() throws {
        let pi = STPFixtures.makePaymentIntent(amount: 100, currency: "USD", setupFutureUsage: .offSession)
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD"), confirmHandler: confirmHandler)
        XCTAssertThrowsError(try PaymentSheetDeferredValidator.validate(paymentIntent: pi,
                                                                        intentConfiguration: intentConfig,
                                                                        paymentMethod: STPPaymentMethod._testCard(),
                                                                        isFlowController: false)) { error in
            XCTAssertEqual("\(error)", "An error occurred in PaymentSheet. Your PaymentIntent setupFutureUsage (offSession) does not match the PaymentSheet.IntentConfiguration setupFutureUsage (nil).")
        }
    }
    
    func testPaymentIntentMismatchedCaptureMethod() throws {
        let pi = STPFixtures.makePaymentIntent(amount: 100, currency: "USD", captureMethod: "manual")
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD", captureMethod: .automatic), confirmHandler: confirmHandler)
        XCTAssertThrowsError(try PaymentSheetDeferredValidator.validate(paymentIntent: pi,
                                                                        intentConfiguration: intentConfig,
                                                                        paymentMethod: STPPaymentMethod._testCard(),
                                                                        isFlowController: false)) { error in
            XCTAssertEqual("\(error)", "An error occurred in PaymentSheet. Your PaymentIntent captureMethod (manual) does not match the PaymentSheet.IntentConfiguration amount (automatic).")
        }
    }
    
    func testPaymentIntentNotFlowControllerManualConfirmationMethod() throws {
        let pi = STPFixtures.makePaymentIntent(amount: 1000, currency: "USD", confirmationMethod: "manual")
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD"), confirmHandler: confirmHandler)
        XCTAssertThrowsError(try PaymentSheetDeferredValidator.validate(paymentIntent: pi,
                                                                        intentConfiguration: intentConfig,
                                                                        paymentMethod: STPPaymentMethod._testCard(),
                                                                        isFlowController: false)) { error in
            XCTAssertEqual("\(error)", "An error occurred in PaymentSheet. Your PaymentIntent confirmationMethod (manual) can only be used with PaymentSheet.FlowController.")
        }
    }
    
    func testPaymentIntentMatchedPaymentMethodId() throws {
        let testCard = STPPaymentMethod._testCard()
        var paymentMethodJson = STPPaymentMethod.paymentMethodJson
        paymentMethodJson["id"] = testCard.stripeId
        let testCardPi = STPFixtures.makePaymentIntent(paymentMethodJson: paymentMethodJson)
        
        XCTAssertNoThrow(try PaymentSheetDeferredValidator.validatePaymentMethod(intentPaymentMethod: testCardPi.paymentMethod,
                                                                                   paymentMethod: testCard))
    }
    
    func testPaymentIntentMismatchedPaymentMethodId() throws {
        let testCard = STPPaymentMethod._testCard()
        var paymentMethodJson = STPPaymentMethod.paymentMethodJson
        paymentMethodJson["id"] = testCard.stripeId
        let testCardPi = STPFixtures.makePaymentIntent(paymentMethodJson: paymentMethodJson)
        let testUSBankAccount = STPPaymentMethod._testUSBankAccount()
        guard let intentPaymentMethod = testCardPi.paymentMethod else {
            return
        }
        XCTAssertThrowsError(try PaymentSheetDeferredValidator.validatePaymentMethod(intentPaymentMethod: testCardPi.paymentMethod,
                                                                                       paymentMethod: testUSBankAccount)) { error in
            XCTAssertEqual("\(error)", """
            An error occurred in PaymentSheet.     \nThere is a mismatch between the payment method ID on your Intent: \(intentPaymentMethod.stripeId) and the payment method passed into the `confirmHandler`: \(testUSBankAccount.stripeId).
            
                To resolve this issue, you can:
                1. Create a new Intent each time before you call the `confirmHandler`, or
                2. Update the existing Intent with the desired `paymentMethod` before calling the `confirmHandler`.
            """)
        }
        let analyticEvent = STPAnalyticsClient.sharedClient._testLogHistory.last
        XCTAssertEqual(analyticEvent?["event"] as? String, STPAnalyticEvent.paymentSheetDeferredIntentPaymentMethodMismatch.rawValue)
        XCTAssertNotNil(analyticEvent?["error_code"] as? String)
    }
    
    func testPaymentIntentMatchedCardFingerprint() throws {
        let testCard = STPPaymentMethod._testCard()
        var paymentMethodJson = STPPaymentMethod.paymentMethodJson
        paymentMethodJson["id"] = "pm_mismatch_id"
        paymentMethodJson["card"] = testCard.card
        let testCardPi = STPFixtures.makePaymentIntent(paymentMethodJson: paymentMethodJson)
        XCTAssertNoThrow(try PaymentSheetDeferredValidator.validatePaymentMethod(intentPaymentMethod: testCardPi.paymentMethod,
                                                                                   paymentMethod: testCard))
    }
    
    func testPaymentIntentMismatchedCardFingerprint() throws {
        let testCard = STPPaymentMethod._testCard()
        var paymentMethodJson = STPPaymentMethod.paymentMethodJson
        paymentMethodJson["id"] = "pm_mismatch_id"
        paymentMethodJson["card"] = ["fingerprint": "mismatch_fingerprint"]
        let testCardPi = STPFixtures.makePaymentIntent(paymentMethodJson: paymentMethodJson)
        guard let intentPaymentMethod = testCardPi.paymentMethod else {
            return
        }
        guard let intentPaymentMethodFingerprint = intentPaymentMethod.card?.fingerprint else {
            return
        }
        guard let testCardFingerprint = testCard.card?.fingerprint else {
            return
        }
        XCTAssertThrowsError(try PaymentSheetDeferredValidator.validatePaymentMethod(intentPaymentMethod: testCardPi.paymentMethod,
                                                                                     paymentMethod: testCard)) { error in
            XCTAssertEqual("\(error)", """
            An error occurred in PaymentSheet.     \nThere is a mismatch between the fingerprint of the payment method on your Intent: \(intentPaymentMethodFingerprint) and the fingerprint of the payment method passed into the `confirmHandler`: \(testCardFingerprint).
            
                To resolve this issue, you can:
                1. Create a new Intent each time before you call the `confirmHandler`, or
                2. Update the existing Intent with the desired `paymentMethod` before calling the `confirmHandler`.
            """)
        }
        let analyticEvent = STPAnalyticsClient.sharedClient._testLogHistory.last
        XCTAssertEqual(analyticEvent?["event"] as? String, STPAnalyticEvent.paymentSheetDeferredIntentPaymentMethodMismatch.rawValue)
        XCTAssertNotNil(analyticEvent?["error_code"] as? String)
    }
    
    func testPaymentIntentMatchedUSBankAccountFingerprint() throws {
        let testUSBankAccount = STPPaymentMethod._testUSBankAccount()
        var paymentMethodJson = STPPaymentMethod.usBankAccountJson
        paymentMethodJson["id"] = "pm_mismatch_id"
        paymentMethodJson["us_bank_account"] = testUSBankAccount.usBankAccount
        let testUSBankAccountPi = STPFixtures.makePaymentIntent(paymentMethodJson: paymentMethodJson)
        XCTAssertNoThrow(try PaymentSheetDeferredValidator.validatePaymentMethod(intentPaymentMethod: testUSBankAccountPi.paymentMethod,
                                                                                   paymentMethod: testUSBankAccount))
    }
    
    func testPaymentIntentMismatchedUSBankAccountFingerprint() throws {
        let testUSBankAccount = STPPaymentMethod._testUSBankAccount()
        var paymentMethodJson = STPPaymentMethod.usBankAccountJson
        paymentMethodJson["id"] = "pm_mismatch_id"
        paymentMethodJson["us_bank_account"] = ["fingerprint": "mismatch_fingerprint"]
        let testUSBankAccountPi = STPFixtures.makePaymentIntent(paymentMethodJson: paymentMethodJson)
        guard let intentPaymentMethod = testUSBankAccountPi.paymentMethod else {
            return
        }
        guard let intentPaymentMethodFingerprint = intentPaymentMethod.card?.fingerprint else {
            return
        }
        guard let testUSBankAccountFingerprint = testUSBankAccount.usBankAccount?.fingerprint else {
            return
        }
        XCTAssertThrowsError(try PaymentSheetDeferredValidator.validatePaymentMethod(intentPaymentMethod: testUSBankAccountPi.paymentMethod,
                                                                                     paymentMethod: testUSBankAccount)) { error in
            XCTAssertEqual("\(error)", """
            An error occurred in PaymentSheet.     \nThere is a mismatch between the fingerprint of the payment method on your Intent: \(intentPaymentMethodFingerprint) and the fingerprint of the payment method passed into the `confirmHandler`: \(testUSBankAccountFingerprint).
            
                To resolve this issue, you can:
                1. Create a new Intent each time before you call the `confirmHandler`, or
                2. Update the existing Intent with the desired `paymentMethod` before calling the `confirmHandler`.
            """)
        }
        let analyticEvent = STPAnalyticsClient.sharedClient._testLogHistory.last
        XCTAssertEqual(analyticEvent?["event"] as? String, STPAnalyticEvent.paymentSheetDeferredIntentPaymentMethodMismatch.rawValue)
        XCTAssertNotNil(analyticEvent?["error_code"] as? String)
    }
    
    func testPaymentIntentNilPaymentMethod() throws {
        let testCard = STPPaymentMethod._testCard()
        let nilPaymentMethodPi = STPFixtures.makePaymentIntent()
        XCTAssertNoThrow(try PaymentSheetDeferredValidator.validatePaymentMethod(intentPaymentMethod: nilPaymentMethodPi.paymentMethod,
                                                                                   paymentMethod: testCard))
    }
    
    func testSetupIntentMatchedPaymentMethodId() throws {
        let testCard = STPPaymentMethod._testCard()
        var paymentMethodJson = STPPaymentMethod.paymentMethodJson
        paymentMethodJson["id"] = testCard.stripeId
        let testCardSi = STPFixtures.makeSetupIntent(paymentMethodJson: paymentMethodJson)
        
        XCTAssertNoThrow(try PaymentSheetDeferredValidator.validatePaymentMethod(intentPaymentMethod: testCardSi.paymentMethod,
                                                                                   paymentMethod: testCard))
    }
    
    func testSetupIntentMismatchedPaymentMethodId() throws {
        let testCard = STPPaymentMethod._testCard()
        var paymentMethodJson = STPPaymentMethod.paymentMethodJson
        paymentMethodJson["id"] = testCard.stripeId
        let testCardSi = STPFixtures.makeSetupIntent(paymentMethodJson: paymentMethodJson)
        let testUSBankAccount = STPPaymentMethod._testUSBankAccount()
        guard let intentPaymentMethod = testCardSi.paymentMethod else {
            return
        }
        XCTAssertThrowsError(try PaymentSheetDeferredValidator.validatePaymentMethod(intentPaymentMethod: testCardSi.paymentMethod,
                                                                                       paymentMethod: testUSBankAccount)) { error in
            XCTAssertEqual("\(error)", """
            An error occurred in PaymentSheet.     \nThere is a mismatch between the payment method ID on your Intent: \(intentPaymentMethod.stripeId) and the payment method passed into the `confirmHandler`: \(testUSBankAccount.stripeId).
            
                To resolve this issue, you can:
                1. Create a new Intent each time before you call the `confirmHandler`, or
                2. Update the existing Intent with the desired `paymentMethod` before calling the `confirmHandler`.
            """)
        }
        let analyticEvent = STPAnalyticsClient.sharedClient._testLogHistory.last
        XCTAssertEqual(analyticEvent?["event"] as? String, STPAnalyticEvent.paymentSheetDeferredIntentPaymentMethodMismatch.rawValue)
        XCTAssertNotNil(analyticEvent?["error_code"] as? String)
    }
    
    func testSetupIntentNilPaymentMethod() throws {
        let testCard = STPPaymentMethod._testCard()
        let nilPaymentMethodSi = STPFixtures.makeSetupIntent()
        XCTAssertNoThrow(try PaymentSheetDeferredValidator.validatePaymentMethod(intentPaymentMethod: nilPaymentMethodSi.paymentMethod,
                                                                                   paymentMethod: testCard))
    }
    
    func testSetupIntentMismatchedUsage() throws {
        let si = STPFixtures.makeSetupIntent(usage: "on_session")
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .setup(currency: "USD", setupFutureUsage: .offSession), confirmHandler: confirmHandler)
        XCTAssertThrowsError(try PaymentSheetDeferredValidator.validate(setupIntent: si, intentConfiguration: intentConfig,
                                                                        paymentMethod: STPPaymentMethod._testCard())) { error in
            XCTAssertEqual("\(error)", "An error occurred in PaymentSheet. Your SetupIntent usage (onSession) does not match the PaymentSheet.IntentConfiguration setupFutureUsage (offSession).")
        }
    }
}
