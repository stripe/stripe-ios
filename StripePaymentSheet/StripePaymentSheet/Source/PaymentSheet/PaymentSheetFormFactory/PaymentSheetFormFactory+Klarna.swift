//
//  PaymentSheetFormFactory+Klarna.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    func makeKlarna() -> PaymentMethodElement {
        let headerElement = makeKlarnaHeader()

        // Email is required by Klarna, name and phone are optional
        let contactInfoSection = makeContactInformationSection(
            nameRequiredByPaymentMethod: false,
            emailRequiredByPaymentMethod: true,
            phoneRequiredByPaymentMethod: false
        )

        let phoneElement = contactInfoSection?.elements.compactMap {
            $0 as? PaymentMethodElementWrapper<PhoneNumberElement>
        }.first

        // Klarna requires a country; collect the full address only if the config requires it
        let addressElement = makeCountryOrAddressSection(
            countries: configuration.billingDetailsCollectionConfiguration.allowedCountriesArray
        )

        connectBillingDetailsFields(
            addressElement: addressElement,
            phoneElement: phoneElement
        )

        // Mandate is required when setting up
        let mandateElement: SimpleMandateElement? = isSettingUp ? makeKlarnaMandate() : nil

        let allElements: [Element?] = [
            headerElement,
            contactInfoSection,
            addressElement,
            mandateElement,
        ]
        return FormElement(autoSectioningElements: allElements.compactMap { $0 }, theme: theme)
    }

    func makeKlarnaMandate() -> SimpleMandateElement {
        let doesMerchantNameEndWithPeriod = configuration.merchantDisplayName.last == "."
        let endOfSentenceMerchantName = doesMerchantNameEndWithPeriod ? String(configuration.merchantDisplayName.dropLast()) : configuration.merchantDisplayName
        let mandateText = String(format: String.Localized.klarna_mandate_text,
                                 configuration.merchantDisplayName,
                                 endOfSentenceMerchantName)
        return makeMandate(mandateText: mandateText)
    }

}
