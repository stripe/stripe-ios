//
//  PaymentSheetFormFactory+Tax.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/18/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    /// Applies tax requirements after the LPM form is built so they replace its country-specific minimums.
    func applyAutomaticTaxMinimumsIfNecessary(to form: PaymentMethodElement) -> PaymentMethodElement {
        guard collectsTaxFromBillingAddress else {
            return form
        }

        let taxMinimums = taxMinimumFieldsToCollectByCountry(autocomplete: .init())
        let addressSections = form.getAllUnwrappedSubElements().compactMap { $0 as? AddressSectionElement }
        stpAssert(
            addressSections.count <= 1,
            "A payment method form should contain at most one billing address section"
        )
        guard let addressSection = addressSections.first else {
            return appendingTaxAddressSection(to: form, minimums: taxMinimums)
        }

        addressSection.addMinimumFieldsToCollectByCountry(taxMinimums)
        return form
    }

    private func appendingTaxAddressSection(
        to form: PaymentMethodElement,
        minimums: [String: AddressSectionElement.FieldsToCollect]
    ) -> PaymentMethodElement {
        // Some LPM forms don't ordinarily collect an address, but billing-sourced tax always needs one.
        let billingAddress = makeBillingAddressSection(
            defaultFieldsToCollect: .country,
            minimumFieldsToCollectByCountry: minimums,
            countries: configuration.billingDetailsCollectionConfiguration.allowedCountriesArray
        )

        return FormElement(elements: [form, billingAddress], theme: theme)
    }

    /// Returns the minimum address fields needed to compute tax in each country.
    private func taxMinimumFieldsToCollectByCountry(
        autocomplete: AddressSectionElement.FieldsToCollect.Autocomplete?
    ) -> [String: AddressSectionElement.FieldsToCollect] {
        return [
            "US": .all(autocomplete: autocomplete),
            "PR": .all(autocomplete: autocomplete),
            "CA": .countryAndPostal,
            "GB": .countryAndPostal,
            "IN": .countryAndPostal,
        ]
    }
}
