//
//  PaymentSheetFormFactory+Affirm.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeUICore
import UIKit

extension PaymentSheetFormFactory {

    func makeAffirm() -> FormElement {
        let header = SubtitleElement(view: AffirmCopyLabel(theme: theme), isHorizontalMode: configuration.isHorizontalMode)
        let contactInfoSection = makeContactInformationSection(
            nameRequiredByPaymentMethod: false,
            emailRequiredByPaymentMethod: false,
            phoneRequiredByPaymentMethod: false
        )
        let billingDetails = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)
        return FormElement(autoSectioningElements: [header, contactInfoSection, billingDetails].compactMap { $0 }, theme: theme)
    }
}
