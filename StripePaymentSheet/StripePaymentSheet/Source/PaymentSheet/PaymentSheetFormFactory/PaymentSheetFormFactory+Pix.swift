//
//  PaymentSheetFormFactory+Pix.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    func makePix() -> PaymentMethodElement {
        // Domestic Pix does not require any Pix-specific fields or disclosure.
        guard countryCode != "BR" else {
            return makeContactInformationAndBillingAddressForm()
        }

        let contactInformation = makeContactInformationSection(
            nameRequiredByPaymentMethod: true,
            emailRequiredByPaymentMethod: true,
            phoneRequiredByPaymentMethod: false
        )
        let taxID = TextFieldElement(
            configuration: IDNumberTextFieldConfiguration(
                type: .BR_CPF_CNPJ,
                label: String.Localized.cpf_cpnj,
                defaultValue: getPreviousCustomerInput(for: "billing_details[tax_id]")
            ),
            theme: theme
        )
        let taxIDSection = SectionElement(
            elements: [PaymentMethodElementWrapper(taxID) { element, params in
                params.paymentMethodParams.additionalAPIParameters["billing_details[tax_id]"] = element.text
                return params
            }, ],
            theme: theme
        )
        let billingAddress = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)
        let disclosure = makeMandate(mandateText: STPStringUtils.applyLinksToString(
            template: String.Localized.pix_international_disclosure,
            links: [
                "terms": URL(string: "https://www.ebanx.com/pt-br/legal/consumidores/brasil/termos-para-processar-pagamentos/")!,
            ]
        ))

        let elements: [Element?] = [contactInformation, taxIDSection, billingAddress, disclosure]
        return FormElement(autoSectioningElements: elements.compactMap { $0 }, theme: theme)
    }
}
