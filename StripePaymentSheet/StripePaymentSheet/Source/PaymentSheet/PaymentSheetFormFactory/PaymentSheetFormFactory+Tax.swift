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
    /// Adds a billing address to forms that don't already build one.
    ///
    /// Existing address sections receive automatic tax minimums in `makeBillingAddressSection`
    /// so their field hierarchy is correct when first rendered.
    func appendingAutomaticTaxAddressIfNecessary(to form: PaymentMethodElement) -> PaymentMethodElement {
        guard collectsTaxFromBillingAddress else {
            return form
        }

        let addressSections = form.getAllUnwrappedSubElements().compactMap { $0 as? AddressSectionElement }
        stpAssert(
            addressSections.count <= 1,
            "A payment method form should contain at most one billing address section"
        )
        guard addressSections.isEmpty else {
            return form
        }

        return appendingAutomaticTaxAddress(to: form)
    }

    /// Returns country-specific minimums widened to include automatic tax requirements.
    func minimumFieldsIncludingAutomaticTax(
        _ minimumFields: [String: AddressSectionElement.FieldsToCollect]
    ) -> [String: AddressSectionElement.FieldsToCollect] {
        guard collectsTaxFromBillingAddress else {
            return minimumFields
        }
        return minimumFields.merging(
            AutomaticTaxBillingAddressRequirements.minimumFieldsToCollectByCountry
        ) { existing, automaticTax in
            existing.widened(toMeet: automaticTax)
        }
    }

    private func appendingAutomaticTaxAddress(to form: PaymentMethodElement) -> PaymentMethodElement {
        // Some LPM forms don't ordinarily collect an address, but billing-sourced tax always needs one.
        let billingAddress = makeBillingAddressSection(
            defaultFieldsToCollect: .country,
            countries: configuration.billingDetailsCollectionConfiguration.allowedCountriesArray
        )

        return FormElement(elements: [form, billingAddress], theme: theme)
    }
}

private extension AddressSectionElement.FieldsToCollect {
    func widened(toMeet minimum: Self) -> Self {
        switch (self, minimum) {
        case (.all, _):
            return self
        case (_, .all):
            return minimum
        case (.countryAndPostal, .country):
            return self
        case (.country, .countryAndPostal):
            return minimum
        case (.countryAndPostal, .countryAndPostal):
            return self
        case (.country, .country):
            return self
        default:
            return self
        }
    }
}
