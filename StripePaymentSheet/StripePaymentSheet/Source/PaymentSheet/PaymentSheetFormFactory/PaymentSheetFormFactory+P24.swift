//
//  PaymentSheetFormFactory+P24.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    func makeP24() -> FormElement {
        // Contact information section (name and email)
        let contactInfoSection = makeContactInformationSection(
            nameRequiredByPaymentMethod: true,
            emailRequiredByPaymentMethod: true,
            phoneRequiredByPaymentMethod: false
        )

        // Bank selector dropdown
        let bankDropdown = makeP24BankDropdown()

        // Billing address section (if needed based on configuration)
        let billingAddressElement = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)

        let allElements: [Element?] = [
            contactInfoSection,
            bankDropdown,
            billingAddressElement,
        ]
        let autoSectioningElements = allElements.compactMap { $0 }
        return FormElement(autoSectioningElements: autoSectioningElements, theme: theme)
    }

    private func makeP24BankDropdown() -> PaymentMethodElementWrapper<DropdownFieldElement> {
        let banks: [(displayText: String, apiValue: String)] = [
            ("Alior Bank", "alior_bank"),
            ("Bank Millenium", "bank_millennium"),
            ("Bank Nowy BFG S.A.", "bank_nowy_bfg_sa"),
            ("Bank PEKAO S.A", "bank_pekao_sa"),
            ("Bank spółdzielczy", "banki_spbdzielcze"),
            ("BLIK", "blik"),
            ("BNP Paribas", "bnp_paribas"),
            ("BOZ", "boz"),
            ("CitiHandlowy", "citi_handlowy"),
            ("Credit Agricole", "credit_agricole"),
            ("e-Transfer Pocztowy24", "etransfer_pocztowy24"),
            ("Getin Bank", "getin_bank"),
            ("IdeaBank", "ideabank"),
            ("ING", "ing"),
            ("inteligo", "inteligo"),
            ("mBank", "mbank_mtransfer"),
            ("Nest Przelew", "nest_przelew"),
            ("Noble Pay", "noble_pay"),
            ("Płać z iPKO (PKO BP)", "pbac_z_ipko"),
            ("Plus Bank", "plus_bank"),
            ("Santander", "santander_przelew24"),
            ("Toyota Bank", "toyota_bank"),
            ("Volkswagen Bank", "volkswagen_bank"),
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
            item.rawData == previousCustomerInput?.paymentMethodParams.przelewy24?.bank
        }

        let dropdownField = DropdownFieldElement(
            items: dropdownItems,
            defaultIndex: previousCustomerInputIndex ?? 0,
            label: STPLocalizedString("Przelewy24 Bank", "Label title for Przelewy24 Bank"),
            theme: theme
        )

        return PaymentMethodElementWrapper(dropdownField) { dropdown, params in
            let selectedBank = dropdown.selectedItem.rawData
            let p24 = params.paymentMethodParams.przelewy24 ?? STPPaymentMethodPrzelewy24Params()
            p24.bank = selectedBank
            params.paymentMethodParams.przelewy24 = p24
            return params
        }
    }
}
