//
//  PaymentSheetFormFactory+Boleto.swift
//  StripePaymentSheet
//
//  Created by Eduardo Urias on 9/11/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    func makeBoleto() -> FormElement {
        let contactInfoSection = makeContactInformationSection(
            nameRequiredByPaymentMethod: true,
            emailRequiredByPaymentMethod: true,
            phoneRequiredByPaymentMethod: false
        )
        let addressSection = configuration.billingDetailsCollectionConfiguration.address != .never
            ? makeBillingAddressSection(countries: ["BR"])
            : nil
        let allElements: [Element?] = [contactInfoSection, makeBoletoTaxID(), addressSection]
        let elements = allElements.compactMap { $0 }
        return FormElement(autoSectioningElements: elements, theme: theme)
    }

    func makeBoletoTaxID() -> SectionElement {
        let taxIDElement = TextFieldElement(
            configuration: IDNumberTextFieldConfiguration(
                type: .BR_CPF_CNPJ,
                label: String.Localized.cpf_cpnj,
                defaultValue: previousCustomerInput?.paymentMethodParams.boleto?.taxID
            ),
            theme: theme
        )
        let taxIDElementWrapper = PaymentMethodElementWrapper(taxIDElement) { element, params in
            params.paymentMethodParams.boleto?.taxID = element.text
            return params
        }
        return SectionElement(
            elements: [taxIDElementWrapper],
            theme: theme
        )
    }
}
