//
//  PaymentSheetFormFactory+BankDebits.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 8/3/26.
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    func makeEPS() -> PaymentMethodElement {
        let name = configuration.billingDetailsCollectionConfiguration.name != .never
            ? makeName(apiPath: "billing_details[name]") : nil
        let email = configuration.billingDetailsCollectionConfiguration.email == .always ? makeEmail() : nil
        let phone = configuration.billingDetailsCollectionConfiguration.phone == .always ? makePhone() : nil
        let bank = makeBankDropdown(
            label: STPLocalizedString("EPS Bank", "Label title for EPS Bank"),
            apiPath: "eps[bank]",
            banks: BankDropdown.eps
        )
        let address = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)
            as? PaymentMethodElementWrapper<AddressSectionElement>
        connectBillingDetailsFields(addressElement: address, phoneElement: phone)
        let elements: [Element?] = [name, email, phone, bank, address]

        return makeDefaultsApplierWrapper(
            for: FormElement(
                autoSectioningElements: elements.compactMap { $0 },
                theme: theme
            )
        )
    }

    func makePrzelewy24() -> PaymentMethodElement {
        let name = configuration.billingDetailsCollectionConfiguration.name != .never
            ? makeName(apiPath: "billing_details[name]") : nil
        let email = configuration.billingDetailsCollectionConfiguration.email != .never
            ? makeEmail(apiPath: "billing_details[email]") : nil
        let phone = configuration.billingDetailsCollectionConfiguration.phone == .always ? makePhone() : nil
        let bank = makeBankDropdown(
            label: STPLocalizedString("Przelewy24 Bank", "Label title for Przelewy24 Bank"),
            apiPath: "p24[bank]",
            banks: BankDropdown.przelewy24
        )
        let address = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)
            as? PaymentMethodElementWrapper<AddressSectionElement>
        connectBillingDetailsFields(addressElement: address, phoneElement: phone)
        let elements: [Element?] = [name, email, phone, bank, address]

        return makeDefaultsApplierWrapper(
            for: FormElement(
                autoSectioningElements: elements.compactMap { $0 },
                theme: theme
            )
        )
    }

    func makeAUBECSDebit() -> PaymentMethodElement {
        let name = configuration.billingDetailsCollectionConfiguration.name != .never
            ? makeName(label: String.Localized.nameOnAccount, apiPath: "billing_details[name]") : nil
        let email = configuration.billingDetailsCollectionConfiguration.email != .never
            ? makeEmail(apiPath: "billing_details[email]") : nil
        let phone = configuration.billingDetailsCollectionConfiguration.phone == .always ? makePhone() : nil
        let bsb = makeBSB(apiPath: "au_becs_debit[bsb_number]")
        let accountNumber = makeAUBECSAccountNumber(apiPath: "au_becs_debit[account_number]")
        let address = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)
            as? PaymentMethodElementWrapper<AddressSectionElement>
        connectBillingDetailsFields(addressElement: address, phoneElement: phone)
        let elements: [Element?] = [
            name,
            email,
            phone,
            bsb,
            accountNumber,
            address,
            makeAUBECSMandate(),
        ]

        return makeDefaultsApplierWrapper(
            for: FormElement(
                autoSectioningElements: elements.compactMap { $0 },
                theme: theme
            )
        )
    }

    func makeFPX() -> PaymentMethodElement {
        let bank = makeBankDropdown(
            label: STPLocalizedString("FPX Bank", "Select a bank dropdown for FPX"),
            apiPath: "fpx[bank]",
            banks: BankDropdown.fpx
        )
        let address = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)
            as? PaymentMethodElementWrapper<AddressSectionElement>
        let name = configuration.billingDetailsCollectionConfiguration.name == .always ? makeName() : nil
        let email = configuration.billingDetailsCollectionConfiguration.email == .always ? makeEmail() : nil
        let phone = configuration.billingDetailsCollectionConfiguration.phone == .always ? makePhone() : nil
        connectBillingDetailsFields(addressElement: address, phoneElement: phone)
        let elements: [Element?] = [bank, address, name, email, phone]

        return makeDefaultsApplierWrapper(
            for: FormElement(
                autoSectioningElements: elements.compactMap { $0 },
                theme: theme
            )
        )
    }

    private func makeBankDropdown(
        label: String,
        apiPath: String,
        banks: [(name: String, value: String)]
    ) -> PaymentMethodElementWrapper<DropdownFieldElement> {
        let items = banks.map {
            DropdownFieldElement.DropdownItem(
                pickerDisplayName: $0.name,
                labelDisplayName: $0.name,
                accessibilityValue: $0.name,
                rawData: $0.value
            )
        }
        let defaultIndex = items.firstIndex {
            $0.rawData == getPreviousCustomerInput(for: apiPath)
        } ?? 0
        let dropdown = DropdownFieldElement(
            items: items,
            defaultIndex: defaultIndex,
            label: label,
            theme: theme
        )
        return PaymentMethodElementWrapper(dropdown) { dropdown, params in
            params.paymentMethodParams.additionalAPIParameters[apiPath] = dropdown.selectedItem.rawData
            return params
        }
    }
}

private enum BankDropdown {
    static let eps: [(name: String, value: String)] = [
        ("Ärzte- und Apothekerbank", "arzte_und_apotheker_bank"),
        ("Austrian Anadi Bank AG", "austrian_anadi_bank_ag"),
        ("Bank Austria", "bank_austria"),
        ("bank99 AG", "brull_kallmus_bank_ag"),
        ("Bankhaus Carl Spängler & Co.AG", "bankhaus_carl_spangler"),
        ("Bankhaus Schelhammer & Schattera AG", "bankhaus_schelhammer_und_schattera_ag"),
        ("BAWAG P.S.K. AG", "bawag_psk_ag"),
        ("BKS Bank AG", "bks_bank_ag"),
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

    static let przelewy24: [(name: String, value: String)] = [
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
        ("VeloBank", "velobank"),
        ("Volkswagen Bank", "volkswagen_bank"),
    ]

    static let fpx: [(name: String, value: String)] = [
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
}
