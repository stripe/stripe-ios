//
//  FormMandateProviderTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 10/4/24.
//

import Foundation
import XCTest
@testable @_spi(EmbeddedPaymentElementPrivateBeta) @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripeCore
@testable import StripeUICore

class FormMandateProviderTests: XCTestCase {

    func testFormMandateProvider_WhenConfigurationHidesMandateText_ShouldReturnNil() {
        var embeddedConfiguration = EmbeddedPaymentElement.Configuration(formSheetAction: .continue)
        embeddedConfiguration.hidesMandateText = true
        embeddedConfiguration.merchantDisplayName = "Test Merchant"

        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"])
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1000, currency: "usd"),
            confirmHandler: { _, _, _ in }
        )
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let formMandateProvider = FormMandateProvider(configuration: embeddedConfiguration, elementsSession: elementsSession, intent: intent)

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
        let formMandateProvider = FormMandateProvider(configuration: configuration, elementsSession: elementsSession, intent: intent)

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
        let formMandateProvider = FormMandateProvider(configuration: configuration, elementsSession: elementsSession, intent: intent)
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
        let formMandateProvider = FormMandateProvider(configuration: configuration, elementsSession: elementsSession, intent: intent)
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
        let formMandateProvider = FormMandateProvider(configuration: configuration, elementsSession: elementsSession, intent: intent)
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
        let formMandateProvider = FormMandateProvider(configuration: configuration, elementsSession: elementsSession, intent: intent)
        let bottomNoticeAttributedString = NSAttributedString(string: "Test Bottom Notice")

        let result = formMandateProvider.mandate(for: .stripe(.USBankAccount), savedPaymentMethod: nil, bottomNoticeAttributedString: bottomNoticeAttributedString)
        XCTAssertEqual(result, bottomNoticeAttributedString)
    }
}
