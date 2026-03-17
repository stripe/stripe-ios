//
//  PaymentSheetFormFactory+iDEAL.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    func makeiDEAL() -> PaymentMethodElement {
        let contactSection: Element? = makeContactInformationSection(
            nameRequiredByPaymentMethod: true,
            emailRequiredByPaymentMethod: isSettingUp,
            phoneRequiredByPaymentMethod: false
        )
        let addressSection: Element? = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)
        let checkboxElement: Element? = makeSepaBasedPMCheckbox()
        // Note: We show a SEPA mandate b/c iDEAL saves bank details as a SEPA Direct Debit Payment Method
        let mandate: Element? = isSettingUp ? makeSepaMandate() : nil
        let elements: [Element?] = [contactSection, addressSection, checkboxElement, mandate]
        return FormElement(
            autoSectioningElements: elements.compactMap { $0 },
            theme: theme
        )
    }
}
