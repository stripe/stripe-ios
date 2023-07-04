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
        let contactInformationElement = makeContactInformation(
            includeName: configuration.billingDetailsCollectionConfiguration.name == .always,
            includeEmail: configuration.billingDetailsCollectionConfiguration.email == .always,
            includePhone: configuration.billingDetailsCollectionConfiguration.phone == .always)
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
        return PaymentMethodElementWrapper(TextFieldElement.makeBlikCode(theme: theme)) { blikCode, params in
            let blik = params.paymentMethodParams.blik ?? STPPaymentMethodBLIKParams()
            
            
            
            params.paymentMethodParams.blik = blik
            return params
        }
    }
}
