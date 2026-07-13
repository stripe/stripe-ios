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

        // Klarna requires country selection
        let countryElement = makeKlarnaCountry()

        // Address without country (Klarna has its own country dropdown)
        let addressElement = makeBillingAddressSection(
            merchantRequestsAddress: configuration.billingDetailsCollectionConfiguration.address == .full,
            fullMode: .noCountry,
            taxMode: .noCountry,
            countries: configuration.billingDetailsCollectionConfiguration.allowedCountriesArray
        )

        connectBillingDetailsFields(
            countryElement: countryElement as? PaymentMethodElementWrapper<DropdownFieldElement>,
            addressElement: addressElement,
            phoneElement: phoneElement
        )

        // Mandate is required when setting up
        let mandateElement: SimpleMandateElement? = isSettingUp ? makeKlarnaMandate() : nil

        let allElements: [Element?] = [
            headerElement,
            contactInfoSection,
            countryElement,
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

    func makeKlarnaCountry() -> PaymentMethodElement? {
        let countryCodes = Locale.current.sortedByTheirLocalizedNames(addressSpecProvider.countries)
        let defaultValue = defaultBillingDetails().address.country
        let country = PaymentMethodElementWrapper(
            DropdownFieldElement.Address.makeCountry(
                label: String.Localized.country,
                countryCodes: countryCodes,
                theme: theme,
                defaultCountry: defaultValue,
                locale: Locale.current
            )
        ) { dropdown, params in
            let countryCode = countryCodes[dropdown.selectedIndex]
            let address = STPPaymentMethodAddress()
            address.country = countryCode
            params.paymentMethodParams.nonnil_billingDetails.address = address
            return params
        }
        return country
    }
}
