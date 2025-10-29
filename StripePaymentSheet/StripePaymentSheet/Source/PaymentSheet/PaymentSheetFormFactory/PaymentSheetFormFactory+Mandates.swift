//
//  PaymentSheetFormFactory+Mandates.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 6/11/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

extension PaymentSheetFormFactory {
    func makeMandate(mandateText: String) -> SimpleMandateElement {
        // If there was previous customer input, check if it displayed the mandate for this payment method
        let customerAlreadySawMandate = previousCustomerInput?.didDisplayMandate ?? false
        return SimpleMandateElement(mandateText: mandateText, customerAlreadySawMandate: customerAlreadySawMandate, theme: theme)
    }

    func makeMandate(mandateText: NSAttributedString) -> SimpleMandateElement {
        // If there was previous customer input, check if it displayed the mandate for this payment method
        let customerAlreadySawMandate = previousCustomerInput?.didDisplayMandate ?? false

        let updatedMandateText = {
            guard isLinkUI else {
                return mandateText
            }

            let mutableString = NSMutableAttributedString(attributedString: mandateText)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineSpacing = LinkUI.mandateLineSpacing
            mutableString.addAttributes([.paragraphStyle: paragraphStyle], range: mutableString.extent)
            return mutableString
        }()

        return SimpleMandateElement(
            mandateText: updatedMandateText,
            customerAlreadySawMandate: customerAlreadySawMandate,
            textAlignment: isLinkUI ? .center : .natural,
            theme: theme
        )
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
        let doesMerchantNameEndWithPeriod = configuration.merchantDisplayName.last == "."
        let endOfSentenceMerchantName = doesMerchantNameEndWithPeriod ? String(configuration.merchantDisplayName.dropLast()) : configuration.merchantDisplayName
        let mandateText = String(format: String.Localized.klarna_mandate_text,
                                 configuration.merchantDisplayName,
                                 endOfSentenceMerchantName)
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

    func makeSatispayMandate() -> SimpleMandateElement {
        let mandateText: String = String(format: String.Localized.satispay_mandate_text, configuration.merchantDisplayName)
        return makeMandate(mandateText: mandateText)
    }
}
