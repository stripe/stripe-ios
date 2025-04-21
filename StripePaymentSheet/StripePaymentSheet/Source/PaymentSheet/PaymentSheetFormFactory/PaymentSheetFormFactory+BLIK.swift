//
//  PaymentSheetFormFactory+BLIK.swift
//  StripePaymentSheet
//
//  Created by Fionn Barrett on 03/07/2023.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

extension PaymentSheetFormFactory {

    func makeBLIK() -> FormElement {
        let contactInformationElement = makeContactInformationSection(nameRequiredByPaymentMethod: false, emailRequiredByPaymentMethod: false, phoneRequiredByPaymentMethod: false)
        let billingAddressElement = configuration.billingDetailsCollectionConfiguration.address == .full
            ? makeBillingAddressSection(countries: nil)
            : nil
        let phoneElement = contactInformationElement?.elements.compactMap {
            $0 as? PaymentMethodElementWrapper<PhoneNumberElement>
        }.first
        connectBillingDetailsFields(
            countryElement: nil,
            addressElement: billingAddressElement,
            phoneElement: phoneElement)

        let allElements: [Element?] = [
            makeCodeField(),
            contactInformationElement,
            billingAddressElement,
        ]
        let autoSectioningElements = allElements.compactMap { $0 }
        return FormElement(autoSectioningElements: autoSectioningElements, theme: theme)
    }

    private func makeCodeField() -> PaymentMethodElementWrapper<TextFieldElement> {
        let previousCustomerInput = previousCustomerInput?.confirmPaymentMethodOptions.blikOptions?.code
        let field = TextFieldElement.makeBlikCode(defaultValue: previousCustomerInput, theme: theme)
        return PaymentMethodElementWrapper(field) { textField, params in
            let blikOptions = STPConfirmBLIKOptions(code: textField.text)
            params.confirmPaymentMethodOptions.blikOptions = blikOptions
            return params
        }
    }
}
