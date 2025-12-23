//
//  PaymentSheetFormFactory+iDEAL.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    func makeiDEAL() -> FormElement {
        // Contact information section (name and email)
        let contactInfoSection = makeContactInformationSection(
            nameRequiredByPaymentMethod: true,
            emailRequiredByPaymentMethod: isSettingUp,
            phoneRequiredByPaymentMethod: false
        )

        // Bank selector dropdown
        let bankDropdown = makeiDEALBankDropdown()

        // Billing address section (if needed based on configuration)
        let billingAddressElement = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)

        // Mandate and checkbox for setup intents
        let mandate: Element? = isSettingUp ? makeSepaMandate() : nil // Note: We show a SEPA mandate b/c iDEAL saves bank details as a SEPA Direct Debit Payment Method
        let checkboxElement = makeSepaBasedPMCheckbox()

        let allElements: [Element?] = [
            contactInfoSection,
            bankDropdown,
            billingAddressElement,
            checkboxElement,
            mandate,
        ]
        let autoSectioningElements = allElements.compactMap { $0 }
        return FormElement(autoSectioningElements: autoSectioningElements, theme: theme)
    }

    private func makeiDEALBankDropdown() -> PaymentMethodElementWrapper<DropdownFieldElement> {
        let banks: [(displayText: String, apiValue: String)] = [
            ("ABN Amro", "abn_amro"),
            ("ASN Bank", "asn_bank"),
            ("bunq B.V.", "bunq"),
            ("ING Bank", "ing"),
            ("Knab", "knab"),
            ("N26", "n26"),
            ("Rabobank", "rabobank"),
            ("RegioBank", "regiobank"),
            ("Revolut", "revolut"),
            ("SNS Bank", "sns_bank"),
            ("Triodos Bank", "triodos_bank"),
            ("Van Lanschot", "van_lanschot"),
            ("Yoursafe", "yoursafe"),
        ]

        let dropdownItems: [DropdownFieldElement.DropdownItem] = banks.map {
            .init(
                pickerDisplayName: $0.displayText,
                labelDisplayName: $0.displayText,
                accessibilityValue: $0.displayText,
                rawData: $0.apiValue
            )
        }

        // Check if there's a previous customer input for this field
        let previousCustomerInputIndex = dropdownItems.firstIndex { item in
            item.rawData == previousCustomerInput?.paymentMethodParams.iDEAL?.bankName
        }

        let dropdownField = DropdownFieldElement(
            items: dropdownItems,
            defaultIndex: previousCustomerInputIndex ?? 0,
            label: String.Localized.ideal_bank,
            theme: theme
        )

        return PaymentMethodElementWrapper(dropdownField) { dropdown, params in
            let selectedBank = dropdown.selectedItem.rawData
            let ideal = params.paymentMethodParams.iDEAL ?? STPPaymentMethodiDEALParams()
            ideal.bankName = selectedBank
            params.paymentMethodParams.iDEAL = ideal
            return params
        }
    }
}
