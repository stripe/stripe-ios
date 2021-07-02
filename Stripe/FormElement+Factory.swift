//
//  FormElement+Factory.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

extension FormElement {
    static func makeBancontact(merchantDisplayName: String) -> FormElement {
        let name = TextFieldElement.Address.makeName()
        let email = TextFieldElement.Address.makeEmail()
        let mandate = StaticElement(view: SepaMandateView(merchantDisplayName: merchantDisplayName))
        return FormElement(elements: [
            SectionElement(elements: [name]),
            SectionElement(elements: [email]),
            CheckboxElement(didToggle: { selected in
                email.isOptional = !selected
                mandate.isHidden = !selected
            }),
            mandate,
        ]) { params in
            params.paymentMethodParams.type = .bancontact
            params.paymentMethodParams.bancontact = STPPaymentMethodBancontactParams()
            return params
        }
    }
    
    static func makeAlipay() -> FormElement {
        return FormElement(elements: []) { params in
            params.paymentMethodParams.type = .alipay
            return params
        }
    }
    
    static func makeSofort(merchantDisplayName: String) -> FormElement {
        /// A hardcoded list of countries that support Sofort
        let sofortDropdownCountries = Set(["AT", "BE", "DE", "IT", "NL", "ES"])
        let country = DropdownFieldElement(
            countryCodes: sofortDropdownCountries
        ) { params, countryCode in
            let sofortParams = params.paymentMethodParams.sofort ?? STPPaymentMethodSofortParams()
            sofortParams.country = countryCode
            params.paymentMethodParams.sofort = sofortParams
            return params
        }
        let name = TextFieldElement.Address.makeName()
        let email = TextFieldElement.Address.makeEmail()
        let mandate = StaticElement(view: SepaMandateView(merchantDisplayName: merchantDisplayName))
        return FormElement(elements: [
            SectionElement(elements: [name]),
            SectionElement(elements: [email]),
            SectionElement(elements: [country]),
            CheckboxElement(didToggle: { selected in
                name.isOptional = !selected
                email.isOptional = !selected
                mandate.isHidden = !selected
            }),
            mandate,
        ]) { params in
            params.paymentMethodParams.type = .sofort
            params.paymentMethodParams.sofort = STPPaymentMethodSofortParams()
            return params
        }
    }
    
    static func makeIdeal(merchantDisplayName: String) -> FormElement {
        let banks = STPiDEALBank.allCases
        
        let bankLabel = STPLocalizedString("Select bank", "label for iDEAL-bank selection picker")
        let bank = DropdownFieldElement(
            items: banks.map { $0.displayName },
            accessibilityLabel: STPLocalizedString(
                "iDEAL Bank",
                "iDEAL bank section title for iDEAL form entry."
            )
        ) { params, selectedIndex in
            let idealParams = params.paymentMethodParams.iDEAL ?? STPPaymentMethodiDEALParams()
            idealParams.bankName = banks[selectedIndex].name
            params.paymentMethodParams.iDEAL = idealParams
            return params
        }
        let name = TextFieldElement.Address.makeName()
        let email = TextFieldElement.Address.makeEmail()
        let mandate = StaticElement(view: SepaMandateView(merchantDisplayName: merchantDisplayName))
        return FormElement(elements: [
            SectionElement(elements: [name]),
            SectionElement(elements: [email]),
            SectionElement(title: bankLabel, elements: [bank]),
            CheckboxElement(didToggle: { selected in
                email.isOptional = !selected
                mandate.isHidden = !selected
            }),
            mandate,
        ]) { params in
            params.paymentMethodParams.type = .iDEAL
            params.paymentMethodParams.iDEAL = STPPaymentMethodiDEALParams()
            return params
        }
    }
    
    static func makeSepa(merchantDisplayName: String) -> FormElement {
        let iban = TextFieldElement.makeIBAN()
        let name = TextFieldElement.Address.makeName()
        let email = TextFieldElement.Address.makeEmail()
        let mandate = StaticElement(view: SepaMandateView(merchantDisplayName: merchantDisplayName))
        return FormElement(elements: [
            SectionElement(elements: [name]),
            SectionElement(elements: [email]),
            SectionElement(elements: [iban]),
            CheckboxElement(didToggle: { selected in
                email.isOptional = !selected
                mandate.isHidden = !selected
            }),
            mandate,
        ]) { params in
            params.paymentMethodParams.type = .SEPADebit
            params.paymentMethodParams.sepaDebit = STPPaymentMethodSEPADebitParams()
            return params
        }
    }
}
