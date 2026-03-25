//
//  PaymentSheetFormFactory+Affirm.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    func makeAffirm() -> PaymentMethodElement {
        let header = SubtitleElement(
            view: AffirmCopyLabel(theme: theme),
            isHorizontalMode: configuration.isHorizontalMode
        )
        let contactInfoSection = makeContactInformationSection(
            nameRequiredByPaymentMethod: false,
            emailRequiredByPaymentMethod: false,
            phoneRequiredByPaymentMethod: false
        )
        let billingDetails = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)
        return FormElement(elements: [header, contactInfoSection, billingDetails].compactMap { $0 }, theme: theme)
    }
}
