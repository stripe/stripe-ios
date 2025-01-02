//
//  FormMandateProviderTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 10/4/24.
//

import Foundation
@testable @_spi(STP) import StripeCore
@testable @_spi(EmbeddedPaymentElementPrivateBeta) @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripeUICore
import XCTest

class FormMandateProviderTests: XCTestCase {

    override func setUp() async throws {
        await PaymentSheetLoader.loadMiscellaneousSingletons()
    }

    func testFormMandateProvider_WhenConfigurationHidesMandateText_ShouldReturnNil() {
        var embeddedConfiguration = EmbeddedPaymentElement.Configuration()
        embeddedConfiguration.embeddedViewDisplaysMandateText = false
        embeddedConfiguration.merchantDisplayName = "Test Merchant"

        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"])
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1000, currency: "usd"),
            confirmHandler: { _, _, _ in }
        )
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let formMandateProvider = VerticalListMandateProvider(configuration: embeddedConfiguration, elementsSession: elementsSession, intent: intent, analyticsHelper: ._testValue())

        let result = formMandateProvider.mandate(for: .stripe(.card), savedPaymentMethod: nil, bottomNoticeAttributedString: nil)
        XCTAssertNil(result)
    }

    func testFormMandateProvider_WhenPaymentMethodTypeIsNil_ShouldReturnNil() {
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"])
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1000, currency: "usd"),
            confirmHandler: { _, _, _ in }
        )
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let formMandateProvider = VerticalListMandateProvider(configuration: configuration, elementsSession: elementsSession, intent: intent, analyticsHelper: ._testValue())

        let result = formMandateProvider.mandate(for: nil, savedPaymentMethod: nil, bottomNoticeAttributedString: nil)
        XCTAssertNil(result)
    }

    func testFormMandateProvider_SavedUSBankAccount_ShouldReturnMandateText() {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Test Merchant"

        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["us_bank_account"])
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1000, currency: "usd"),
            confirmHandler: { _, _, _ in }
        )
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let formMandateProvider = VerticalListMandateProvider(configuration: configuration, elementsSession: elementsSession, intent: intent, analyticsHelper: ._testValue())
        let paymentMethod: STPPaymentMethod = ._testUSBankAccount()

        let result = formMandateProvider.mandate(for: .stripe(.USBankAccount), savedPaymentMethod: paymentMethod, bottomNoticeAttributedString: nil)
        let expectedText = USBankAccountPaymentMethodElement.attributedMandateTextSavedPaymentMethod(alignment: .natural, theme: configuration.appearance.asElementsTheme)
        XCTAssertEqual(result, expectedText)
    }

    func testFormMandateProvider_SavedSEPADebit_ShouldReturnMandateText() {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Test Merchant"

        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["sepa_debit"])
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1000, currency: "eur"),
            confirmHandler: { _, _, _ in }
        )
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let formMandateProvider = VerticalListMandateProvider(configuration: configuration, elementsSession: elementsSession, intent: intent, analyticsHelper: ._testValue())
        let paymentMethod: STPPaymentMethod = ._testSEPA()

        let result = formMandateProvider.mandate(for: .stripe(.SEPADebit), savedPaymentMethod: paymentMethod, bottomNoticeAttributedString: nil)
        let expectedString = String(format: String.Localized.sepa_mandate_text, configuration.merchantDisplayName)
        XCTAssertEqual(result?.string, expectedString)
    }

    func testFormMandateProvider_SavedOtherPaymentMethod_ShouldReturnNil() {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Test Merchant"

        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"])
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1000, currency: "usd"),
            confirmHandler: { _, _, _ in }
        )
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let formMandateProvider = VerticalListMandateProvider(configuration: configuration, elementsSession: elementsSession, intent: intent, analyticsHelper: ._testValue())
        let paymentMethod: STPPaymentMethod = ._testCard()

        let result = formMandateProvider.mandate(for: .stripe(.card), savedPaymentMethod: paymentMethod, bottomNoticeAttributedString: nil)

        XCTAssertNil(result)
    }

    func testFormMandateProvider_BottomNoticeAttributedStringProvided_ShouldReturnIt() {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Test Merchant"

        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["us_bank_account"])
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1000, currency: "usd"),
            confirmHandler: { _, _, _ in }
        )
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let formMandateProvider = VerticalListMandateProvider(configuration: configuration, elementsSession: elementsSession, intent: intent, analyticsHelper: ._testValue())
        let bottomNoticeAttributedString = NSAttributedString(string: "Test Bottom Notice")

        let result = formMandateProvider.mandate(for: .stripe(.USBankAccount), savedPaymentMethod: nil, bottomNoticeAttributedString: bottomNoticeAttributedString)
        XCTAssertEqual(result, bottomNoticeAttributedString)
    }

    func testFormMandateProvider_cashApp_settingUp_shouldReturnMandate() {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Test Merchant"

        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["cashapp"])
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .setup(currency: "USD", setupFutureUsage: .offSession),
            confirmHandler: { _, _, _ in }
        )
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let formMandateProvider = VerticalListMandateProvider(configuration: configuration, elementsSession: elementsSession, intent: intent, analyticsHelper: ._testValue())

        let result = formMandateProvider.mandate(for: .stripe(.cashApp), savedPaymentMethod: nil, bottomNoticeAttributedString: nil)
        let expected = "By continuing, you authorize Test Merchant to debit your Cash App account for this payment and future payments in accordance with Test Merchant\'s terms, until this authorization is revoked. You can change this anytime in your Cash App Settings."
        XCTAssertEqual(result?.string, expected)
    }

    func testFormMandateProvider_cashApp_settingWithSetupFutureUsage_shouldReturnMandate() {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Test Merchant"

        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["cashapp"])
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1000, currency: "USD", setupFutureUsage: .onSession),
            confirmHandler: { _, _, _ in }
        )
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let formMandateProvider = VerticalListMandateProvider(configuration: configuration, elementsSession: elementsSession, intent: intent, analyticsHelper: ._testValue())

        let result = formMandateProvider.mandate(for: .stripe(.cashApp), savedPaymentMethod: nil, bottomNoticeAttributedString: nil)
        let expected = "By continuing, you authorize Test Merchant to debit your Cash App account for this payment and future payments in accordance with Test Merchant\'s terms, until this authorization is revoked. You can change this anytime in your Cash App Settings."
        XCTAssertEqual(result?.string, expected)
    }

    func testFormMandateProvider_cashApp_settingUp_shouldNotReturnMandate() {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Test Merchant"

        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["cashapp"])
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 100, currency: "USD"),
            confirmHandler: { _, _, _ in }
        )
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let formMandateProvider = VerticalListMandateProvider(configuration: configuration, elementsSession: elementsSession, intent: intent, analyticsHelper: ._testValue())

        let result = formMandateProvider.mandate(for: .stripe(.cashApp), savedPaymentMethod: nil, bottomNoticeAttributedString: nil)
        XCTAssertNil(result)
    }

}
