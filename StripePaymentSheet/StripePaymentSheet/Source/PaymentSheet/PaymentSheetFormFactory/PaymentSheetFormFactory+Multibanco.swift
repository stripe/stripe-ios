//
//  PaymentSheetFormFactory+Multibanco.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    func makeMultibanco() -> FormElement {
        // Contact information (email required by Multibanco)
        let contactInfoSection = makeContactInformationSection(
            nameRequiredByPaymentMethod: false,
            emailRequiredByPaymentMethod: true,
            phoneRequiredByPaymentMethod: false
        )

        // Billing address (returns nil unless config is .full or .automatic with requirement)
        let billingAddressElement = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)

        let allElements: [Element?] = [contactInfoSection, billingAddressElement]
        let autoSectioningElements = allElements.compactMap { $0 }
        return FormElement(autoSectioningElements: autoSectioningElements, theme: theme)
    }
}
