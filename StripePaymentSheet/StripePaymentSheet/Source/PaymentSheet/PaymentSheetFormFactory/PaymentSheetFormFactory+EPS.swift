//
//  PaymentSheetFormFactory+EPS.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    func makeEPS() -> FormElement {
        // Contact information section (name and email)
        let contactInfoSection = makeContactInformationSection(
            nameRequiredByPaymentMethod: true,
            emailRequiredByPaymentMethod: isSettingUp,
            phoneRequiredByPaymentMethod: false
        )

        // Bank selector dropdown
        let bankDropdown = makeEPSBankDropdown()

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

    private func makeEPSBankDropdown() -> PaymentMethodElementWrapper<DropdownFieldElement> {
        let banks: [(displayText: String, apiValue: String)] = [
            ("Ärzte- und Apothekerbank", "arzte_und_apotheker_bank"),
            ("Austrian Anadi Bank AG", "austrian_anadi_bank_ag"),
            ("Bank Austria", "bank_austria"),
            ("Bankhaus Carl Spängler & Co.AG", "bankhaus_carl_spangler"),
            ("Bankhaus Schelhammer & Schattera AG", "bankhaus_schelhammer_und_schattera_ag"),
            ("BAWAG P.S.K. AG", "bawag_psk_ag"),
            ("BKS Bank AG", "bks_bank_ag"),
            ("Brüll Kallmus Bank AG", "brull_kallmus_bank_ag"),
            ("BTV VIER LÄNDER BANK", "btv_vier_lander_bank"),
            ("Capital Bank Grawe Gruppe AG", "capital_bank_grawe_gruppe_ag"),
            ("Dolomitenbank", "dolomitenbank"),
            ("Easybank AG", "easybank_ag"),
            ("Erste Bank und Sparkassen", "erste_bank_und_sparkassen"),
            ("Hypo Alpe-Adria-Bank International AG", "hypo_alpeadriabank_international_ag"),
            ("HYPO NOE LB für Niederösterreich u. Wien", "hypo_noe_lb_fur_niederosterreich_u_wien"),
            ("HYPO Oberösterreich,Salzburg,Steiermark", "hypo_oberosterreich_salzburg_steiermark"),
            ("Hypo Tirol Bank AG", "hypo_tirol_bank_ag"),
            ("Hypo Vorarlberg Bank AG", "hypo_vorarlberg_bank_ag"),
            ("HYPO-BANK BURGENLAND Aktiengesellschaft", "hypo_bank_burgenland_aktiengesellschaft"),
            ("Marchfelder Bank", "marchfelder_bank"),
            ("Oberbank AG", "oberbank_ag"),
            ("Raiffeisen Bankengruppe Österreich", "raiffeisen_bankengruppe_osterreich"),
            ("Schoellerbank AG", "schoellerbank_ag"),
            ("Sparda-Bank Wien", "sparda_bank_wien"),
            ("Volksbank Gruppe", "volksbank_gruppe"),
            ("Volkskreditbank AG", "volkskreditbank_ag"),
            ("VR-Bank Braunau", "vr_bank_braunau"),
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
            item.rawData == previousCustomerInput?.paymentMethodParams.eps?.bank
        }

        let dropdownField = DropdownFieldElement(
            items: dropdownItems,
            defaultIndex: previousCustomerInputIndex ?? 0,
            label: STPLocalizedString("EPS Bank", "Label title for EPS Bank"),
            theme: theme
        )

        return PaymentMethodElementWrapper(dropdownField) { dropdown, params in
            let selectedBank = dropdown.selectedItem.rawData
            let eps = params.paymentMethodParams.eps ?? STPPaymentMethodEPSParams()
            eps.bank = selectedBank
            params.paymentMethodParams.eps = eps
            return params
        }
    }
}
