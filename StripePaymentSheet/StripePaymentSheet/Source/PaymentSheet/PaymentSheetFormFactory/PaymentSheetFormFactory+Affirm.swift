//
//  PaymentSheetFormFactory+Affirm.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    func makeAffirm() -> FormElement {
        // Affirm header
        let header = SubtitleElement(view: AffirmCopyLabel(theme: theme), isHorizontalMode: configuration.isHorizontalMode)

        // Contact information (returns nil if config is .never for all fields)
        let contactInfoSection = makeContactInformationSection(
            nameRequiredByPaymentMethod: false,
            emailRequiredByPaymentMethod: false,
            phoneRequiredByPaymentMethod: false
        )

        // Billing address (returns nil unless config is .full or .automatic with requirement)
        let billingAddressElement = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)

        let allElements: [Element?] = [header, contactInfoSection, billingAddressElement]
        let autoSectioningElements = allElements.compactMap { $0 }
        return FormElement(autoSectioningElements: autoSectioningElements, theme: theme)
    }
}
