//
//  PaymentSheetFormFactory+AUBECSDebit.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    func makeAUBECSDebit() -> FormElement {
        // Contact information section (name with "on account" label and email)
        let contactInfoSection = makeContactInformationSection(
            nameRequiredByPaymentMethod: true,
            emailRequiredByPaymentMethod: true,
            phoneRequiredByPaymentMethod: false
        )

        // Bank account details (BSB and account number)
        let bsbField = makeBSB()
        let accountNumberField = makeAUBECSAccountNumber()
        let bankAccountSection = SectionElement(
            title: String.Localized.bank_account_sentence_case,
            elements: [bsbField, accountNumberField],
            theme: theme
        )

        // Billing address section (if needed based on configuration)
        let billingAddressElement = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)

        // Mandate
        let mandate = makeAUBECSMandate()

        let allElements: [Element?] = [
            contactInfoSection,
            bankAccountSection,
            billingAddressElement,
            mandate,
        ]
        let autoSectioningElements = allElements.compactMap { $0 }
        return FormElement(autoSectioningElements: autoSectioningElements, theme: theme)
    }
}
