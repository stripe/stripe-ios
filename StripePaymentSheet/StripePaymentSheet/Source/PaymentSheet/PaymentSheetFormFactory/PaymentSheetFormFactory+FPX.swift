//
//  PaymentSheetFormFactory+FPX.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    func makeFPX() -> FormElement {
        // Bank selector dropdown
        let bankDropdown = makeFPXBankDropdown()

        // Billing address section (if needed based on configuration)
        let billingAddressElement = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)

        let allElements: [Element?] = [
            bankDropdown,
            billingAddressElement,
        ]
        let autoSectioningElements = allElements.compactMap { $0 }
        return FormElement(autoSectioningElements: autoSectioningElements, theme: theme)
    }

    private func makeFPXBankDropdown() -> PaymentMethodElementWrapper<DropdownFieldElement> {
        let banks: [(displayText: String, apiValue: String)] = [
            ("Affin Bank", "affin_bank"),
            ("Alliance Bank", "alliance_bank"),
            ("AmBank", "ambank"),
            ("Bank Islam", "bank_islam"),
            ("Bank Muamalat", "bank_muamalat"),
            ("Bank Rakyat", "bank_rakyat"),
            ("BSN", "bsn"),
            ("CIMB Clicks", "cimb"),
            ("Hong Leong Bank", "hong_leong_bank"),
            ("HSBC BANK", "hsbc"),
            ("KFH", "kfh"),
            ("Maybank2E", "maybank2e"),
            ("Maybank2U", "maybank2u"),
            ("OCBC Bank", "ocbc"),
            ("Public Bank", "public_bank"),
            ("RHB Bank", "rhb"),
            ("Standard Chartered", "standard_chartered"),
            ("UOB Bank", "uob"),
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
            item.rawData == previousCustomerInput?.paymentMethodParams.fpx?.rawBankString
        }

        let dropdownField = DropdownFieldElement(
            items: dropdownItems,
            defaultIndex: previousCustomerInputIndex ?? 0,
            label: STPLocalizedString("FPX Bank", "Select a bank dropdown for FPX"),
            theme: theme
        )

        return PaymentMethodElementWrapper(dropdownField) { dropdown, params in
            let selectedBank = dropdown.selectedItem.rawData
            let fpx = params.paymentMethodParams.fpx ?? STPPaymentMethodFPXParams()
            fpx.rawBankString = selectedBank
            params.paymentMethodParams.fpx = fpx
            return params
        }
    }
}
