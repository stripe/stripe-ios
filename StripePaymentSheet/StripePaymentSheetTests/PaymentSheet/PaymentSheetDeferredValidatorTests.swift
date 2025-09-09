//
//  PaymentSheetDeferredValidatorTests.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 5/16/23.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) @_spi(ConfirmationTokensPublicPreview) import StripePayments
@testable@_spi(STP) @_spi(PaymentMethodOptionsSetupFutureUsagePreview) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
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
            XCTAssertEqual("\(error)", "An error occurred in PaymentSheet. Your PaymentIntent setupFutureUsage (offSession) does not match the IntentConfiguration setupFutureUsage (nil).")
        }
    }

    func testPaymentIntentAllowsSetupFutureUsageOffSessionAndOnSessionMismatch() throws {
        // Top-level SFU
        let pi = STPFixtures.makePaymentIntent(amount: 100, currency: "USD", setupFutureUsage: .offSession)
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD", setupFutureUsage: .onSession), confirmHandler: confirmHandler)
        try PaymentSheetDeferredValidator.validate(
            paymentIntent: pi,
            intentConfiguration: intentConfig,
            paymentMethod: STPPaymentMethod._testCard(),
            isFlowController: false
        )

        // PMO SFU
        let pi_with_pmo_sfu_on_session = STPFixtures.makePaymentIntent(
            amount: 100,
            currency: "USD",
            paymentMethodTypes: [.card],
            paymentMethodOptions: STPPaymentMethodOptions(
                usBankAccount: nil,
                card: nil,
                allResponseFields: ["card": ["setup_future_usage": "on_session"]]
            )
        )
        let intentConfig_with_pmo_sfu_off_session = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD", paymentMethodOptions: .init(setupFutureUsageValues: [.card: .offSession])), confirmHandler: confirmHandler)
        try PaymentSheetDeferredValidator.validate(
            paymentIntent: pi_with_pmo_sfu_on_session,
            intentConfiguration: intentConfig_with_pmo_sfu_off_session,
            paymentMethod: STPPaymentMethod._testCard(),
            isFlowController: false
        )
    }

    func testPaymentIntentConfigurationNoneTopLevelSetupFutureUsage() throws {
        let pi = STPFixtures.makePaymentIntent(amount: 100, currency: "USD")
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD", setupFutureUsage: PaymentSheet.IntentConfiguration.SetupFutureUsage.none), confirmHandler: confirmHandler)
        XCTAssertThrowsError(try PaymentSheetDeferredValidator.validate(paymentIntent: pi,
                                                                        intentConfiguration: intentConfig,
                                                                        paymentMethod: STPPaymentMethod._testCard(),
                                                                        isFlowController: false)) { error in
            XCTAssertEqual("\(error)", "An error occurred in PaymentSheet. Your IntentConfiguration setupFutureUsage (none) is invalid. You can only set it to `.onSession`, `.offSession`, or leave it `nil`.")
        }
    }

    func makeIntentConfiguration(topLevelSFU: PaymentSheet.IntentConfiguration.SetupFutureUsage?, pmoSFU: PaymentSheet.IntentConfiguration.SetupFutureUsage?) -> PaymentSheet.IntentConfiguration {
        return PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 100,
                currency: "USD",
                setupFutureUsage: topLevelSFU,
                paymentMethodOptions: .init(setupFutureUsageValues: pmoSFU != nil ? [.card: pmoSFU!] : [:])
            ),
            confirmHandler: confirmHandler
        )
    }

    func test_validates_payment_intent_with_unset_sfu_and_pmo_sfu_values() throws {
        // Given a PI without PMO SFU or SFU set...
        let pi_without_pmo_sfu_or_sfu = STPFixtures.makePaymentIntent(amount: 100, currency: "USD")
        // ...validation should pass regardless of the IntentConfig
        let intentConfig_with_pmo_set = makeIntentConfiguration(topLevelSFU: nil, pmoSFU: .offSession)
        try PaymentSheetDeferredValidator.validate(
            paymentIntent: pi_without_pmo_sfu_or_sfu,
            intentConfiguration: intentConfig_with_pmo_set,
            paymentMethod: STPPaymentMethod._testCard(),
            isFlowController: false
        )

        let intentConfig_with_sfu_and_pmo_sfu_set = makeIntentConfiguration(topLevelSFU: .offSession, pmoSFU: .offSession)
        try PaymentSheetDeferredValidator.validate(
            paymentIntent: pi_without_pmo_sfu_or_sfu,
            intentConfiguration: intentConfig_with_sfu_and_pmo_sfu_set,
            paymentMethod: STPPaymentMethod._testCard(),
            isFlowController: false
        )

        let intentConfig_with_none_set = makeIntentConfiguration(topLevelSFU: nil, pmoSFU: nil)
        try PaymentSheetDeferredValidator.validate(
            paymentIntent: pi_without_pmo_sfu_or_sfu,
            intentConfiguration: intentConfig_with_none_set,
            paymentMethod: STPPaymentMethod._testCard(),
            isFlowController: false
        )
    }

    func test_validates_payment_intent_sfu_and_pmo_sfu_values_match_intent_config() throws {
        // PI and IntentConfig with matching SFU values...
        let pi_matching = STPFixtures.makePaymentIntent(
            amount: 100,
            currency: "USD",
            paymentMethodTypes: [.card],
            setupFutureUsage: .offSession,
            paymentMethodOptions: STPPaymentMethodOptions(
                usBankAccount: nil,
                card: nil,
                allResponseFields: ["card": ["setup_future_usage": "none"]]
            )
        )
        let intentConfig_matching = makeIntentConfiguration(topLevelSFU: .offSession, pmoSFU: PaymentSheet.IntentConfiguration.SetupFutureUsage.none)
        // ...should succeed validation
        XCTAssertNoThrow(try PaymentSheetDeferredValidator.validate(
            paymentIntent: pi_matching,
            intentConfiguration: intentConfig_matching,
            paymentMethod: STPPaymentMethod._testCard(),
            isFlowController: false
        ))

        // PI and IntentConfig with differing SFU values...
        let pi_sfu_off_session = STPFixtures.makePaymentIntent(
            amount: 100,
            currency: "USD",
            paymentMethodTypes: [.card],
            setupFutureUsage: .offSession
        )
        let intentConfig_sfu_nil = makeIntentConfiguration(topLevelSFU: nil, pmoSFU: nil)
        // ...should fail validation
        XCTAssertThrowsError(try PaymentSheetDeferredValidator.validate(
            paymentIntent: pi_sfu_off_session,
            intentConfiguration: intentConfig_sfu_nil,
            paymentMethod: STPPaymentMethod._testCard(),
            isFlowController: false
        )) { error in
            XCTAssertEqual("\(error)", "An error occurred in PaymentSheet. Your PaymentIntent setupFutureUsage (offSession) does not match the IntentConfiguration setupFutureUsage (nil).")
        }

        // PI and IntentConfig with differing PMO SFU values...
        let pi_with_pmo_sfu_none = STPFixtures.makePaymentIntent(
            amount: 100,
            currency: "USD",
            paymentMethodTypes: [.card],
            setupFutureUsage: .offSession,
            paymentMethodOptions: STPPaymentMethodOptions(
                usBankAccount: nil,
                card: nil,
                allResponseFields: ["card": ["setup_future_usage": "none"]]
            )
        )
        let intentConfig_with_pmo_sfu_nil = makeIntentConfiguration(topLevelSFU: .offSession, pmoSFU: nil)
        // ...should fail validation
        XCTAssertThrowsError(try PaymentSheetDeferredValidator.validate(
            paymentIntent: pi_with_pmo_sfu_none,
            intentConfiguration: intentConfig_with_pmo_sfu_nil,
            paymentMethod: STPPaymentMethod._testCard(),
            isFlowController: false
        )) { error in
            XCTAssertEqual("\(error)", "An error occurred in PaymentSheet. Your PaymentIntent payment_method_options[card][setup_future_usage] value (none) does not match the IntentConfiguration value (nil)")
        }
    }

    func testPaymentIntentConfigurationPaymentMethodOptionsSetupFutureUsage() throws {
        // different order
        var pi = STPFixtures.makePaymentIntent(amount: 100, currency: "USD", paymentMethodTypes: [.card, .USBankAccount], paymentMethodOptions: STPPaymentMethodOptions(usBankAccount: nil, card: nil, allResponseFields: ["card": ["setup_future_usage": "off_session"], "us_bank_account": ["setup_future_usage": "off_session"]]))
        var intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD", paymentMethodOptions: PaymentSheet.IntentConfiguration.Mode.PaymentMethodOptions(setupFutureUsageValues: [.USBankAccount: .offSession, .card: .offSession])), confirmHandler: confirmHandler)
        XCTAssertNoThrow(try PaymentSheetDeferredValidator.validate(paymentIntent: pi,
                                                                        intentConfiguration: intentConfig,
                                                                        paymentMethod: STPPaymentMethod._testCard(),
                                                                        isFlowController: false))
        // both nil
        pi = STPFixtures.makePaymentIntent(amount: 100, currency: "USD")
        intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD"), confirmHandler: confirmHandler)
        XCTAssertNoThrow(try PaymentSheetDeferredValidator.validate(paymentIntent: pi,
                                                                        intentConfiguration: intentConfig,
                                                                        paymentMethod: STPPaymentMethod._testCard(),
                                                                        isFlowController: false))
        // pi pmo non-nil but not sfu-related
        pi = STPFixtures.makePaymentIntent(amount: 100, currency: "USD", paymentMethodTypes: [.card], paymentMethodOptions: STPPaymentMethodOptions(usBankAccount: nil, card: .init(requireCvcRecollection: true, cvcToken: "1234", allResponseFields: ["require_cvc_recollection": true, "cvc_token": "1234"]), allResponseFields: ["card": ["require_cvc_recollection": true]]))
        intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD"), confirmHandler: confirmHandler)
        XCTAssertNoThrow(try PaymentSheetDeferredValidator.validate(paymentIntent: pi,
                                                                        intentConfiguration: intentConfig,
                                                                        paymentMethod: STPPaymentMethod._testCard(),
                                                                        isFlowController: false))
        // pi sepa_debit got filtered out, but sepa_debit pmo sfu set on the IntentConfiguration
        pi = STPFixtures.makePaymentIntent(amount: 100, currency: "USD", paymentMethodTypes: [.card, .USBankAccount], paymentMethodOptions: STPPaymentMethodOptions(usBankAccount: nil, card: nil, allResponseFields: ["card": ["setup_future_usage": "off_session"], "us_bank_account": ["setup_future_usage": "off_session"]]))
        intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD", paymentMethodOptions: PaymentSheet.IntentConfiguration.Mode.PaymentMethodOptions(setupFutureUsageValues: [.USBankAccount: .offSession, .card: .offSession, .SEPADebit: .offSession])), confirmHandler: confirmHandler)
        XCTAssertNoThrow(try PaymentSheetDeferredValidator.validate(paymentIntent: pi,
                                                                        intentConfiguration: intentConfig,
                                                                        paymentMethod: STPPaymentMethod._testCard(),
                                                                        isFlowController: false))

        // intent pmo and intent config pmo have things that don't match, but for the payment method types on the intent, they do
        pi = STPFixtures.makePaymentIntent(amount: 100, currency: "USD", paymentMethodTypes: [.card, .USBankAccount], paymentMethodOptions: STPPaymentMethodOptions(usBankAccount: nil, card: nil, allResponseFields: ["card": ["setup_future_usage": "off_session"], "us_bank_account": ["setup_future_usage": "off_session", "cashapp": "on_session"]]))
        intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD", paymentMethodOptions: PaymentSheet.IntentConfiguration.Mode.PaymentMethodOptions(setupFutureUsageValues: [.USBankAccount: .offSession, .card: .offSession, .SEPADebit: .offSession])), confirmHandler: confirmHandler)
        XCTAssertNoThrow(try PaymentSheetDeferredValidator.validate(paymentIntent: pi,
                                                                        intentConfiguration: intentConfig,
                                                                        paymentMethod: STPPaymentMethod._testCard(),
                                                                        isFlowController: false))
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
}
