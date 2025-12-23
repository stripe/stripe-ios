//
//  PaymentSheetFormFactory+Klarna.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    func makeKlarnaExplicit() -> FormElement {
        // Klarna header
        let header = makeCopyLabel(text: .Localized.buy_now_or_pay_later_with_klarna)

        // Email field
        let contactInfoSection = makeContactInformationSection(
            nameRequiredByPaymentMethod: false,
            emailRequiredByPaymentMethod: true,
            phoneRequiredByPaymentMethod: false
        )

        // Klarna country selector
        let countryElement = makeKlarnaCountry(apiPath: "billing_details[address][country]")

        // Billing address section (without country since klarna_country handles it)
        let billingAddressElement: Element? = {
            if configuration.billingDetailsCollectionConfiguration.address == .full {
                return makeBillingAddressSection(collectionMode: .noCountry, countries: configuration.billingDetailsCollectionConfiguration.allowedCountriesArray)
            }
            return nil
        }()

        // Connect country and address fields
        if let countryDropdown = countryElement as? PaymentMethodElementWrapper<DropdownFieldElement>,
           let addressSection = billingAddressElement as? PaymentMethodElementWrapper<AddressSectionElement> {
            connectBillingDetailsFields(
                countryElement: countryDropdown,
                addressElement: addressSection,
                phoneElement: nil
            )
        }

        // Mandate for setup intents
        let mandate: Element? = isSettingUp ? makeKlarnaMandate() : nil

        let allElements: [Element?] = [
            header,
            contactInfoSection,
            countryElement,
            billingAddressElement,
            mandate,
        ]
        let autoSectioningElements = allElements.compactMap { $0 }
        return FormElement(autoSectioningElements: autoSectioningElements, theme: theme)
    }
}
