//
//  PaymentSheetFormFactory+Mandates.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 6/11/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

extension PaymentSheetFormFactory {
    func makeMandate(mandateText: String) -> SimpleMandateElement {
        // If there was previous customer input, check if it displayed the mandate for this payment method
        let customerAlreadySawMandate = previousCustomerInput?.didDisplayMandate ?? false
        return SimpleMandateElement(mandateText: mandateText, customerAlreadySawMandate: customerAlreadySawMandate, theme: theme)
    }

    func makeAUBECSMandate() -> StaticElement {
        return StaticElement(view: AUBECSLegalTermsView(configuration: configuration))
    }

    func makeBacsMandate() -> PaymentMethodElementWrapper<CheckboxElement> {
        let mandateText = String(format: String.Localized.bacs_mandate_text, configuration.merchantDisplayName)
        let element = CheckboxElement(
            theme: configuration.appearance.asElementsTheme,
            label: mandateText,
            // If the previous customer input is non-nil, it means the customer checked the box (see 🍞)
            isSelectedByDefault: previousCustomerInput != nil
        )
        return PaymentMethodElementWrapper(element) { checkbox, params in
            // 🍞 Only return params if the mandate has been accepted
            return checkbox.isSelected ? params : nil
        }
    }

    func makeSepaMandate() -> SimpleMandateElement {
        let mandateText = String(format: String.Localized.sepa_mandate_text, configuration.merchantDisplayName)
        return makeMandate(mandateText: mandateText)
    }

    func makeCashAppMandate() -> SimpleMandateElement {
        let mandateText = String(format: String.Localized.cash_app_mandate_text, configuration.merchantDisplayName, configuration.merchantDisplayName)
        return makeMandate(mandateText: mandateText)
    }

    func makeRevolutPayMandate() -> SimpleMandateElement {
        let mandateText = String(format: String.Localized.revolut_pay_mandate_text, configuration.merchantDisplayName)
        return makeMandate(mandateText: mandateText)
    }

    func makeKlarnaMandate() -> SimpleMandateElement {
        let mandateText = String(format: String.Localized.klarna_mandate_text,
                                 configuration.merchantDisplayName,
                                 configuration.merchantDisplayName)
        return makeMandate(mandateText: mandateText)
    }

    func makeAmazonPayMandate() -> SimpleMandateElement {
        let mandateText = String(format: String.Localized.amazon_pay_mandate_text, configuration.merchantDisplayName)
        return makeMandate(mandateText: mandateText)
    }

    func makePaypalMandate() -> SimpleMandateElement {
        let mandateText: String = {
            if isPaymentIntent {
                return String(format: String.Localized.paypal_mandate_text_payment, configuration.merchantDisplayName)
            } else {
                return String(format: String.Localized.paypal_mandate_text_setup, configuration.merchantDisplayName)
            }
        }()
        return makeMandate(mandateText: mandateText)
    }
}
