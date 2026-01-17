//
//  PaymentSheetFormFactory+AfterpayClearpay.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    func makeAfterpayClearpay() -> FormElement {
        // Afterpay/Clearpay header with price breakdown
        let header = makeAfterpayClearpayHeader()

        // Contact information section (name and email)
        let contactInfoSection = makeContactInformationSection(
            nameRequiredByPaymentMethod: true,
            emailRequiredByPaymentMethod: true,
            phoneRequiredByPaymentMethod: false
        )

        // Billing address section
        let billingAddressElement = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: true)

        let allElements: [Element?] = [
            header,
            contactInfoSection,
            billingAddressElement,
        ]
        let autoSectioningElements = allElements.compactMap { $0 }
        return FormElement(autoSectioningElements: autoSectioningElements, theme: theme)
    }
}
