//
//  FormElement+Factory.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

extension FormElement {
    struct Configuration {
        let canSave: Bool
        let merchantDisplayName: String
    }
    
    /// Conveniently nests single TextField and DropdownFields in a Section
    fileprivate convenience init(_ autoSectioningElements: [Element]) {
        let elements: [Element] = autoSectioningElements.map {
            if $0 is TextFieldElement || $0 is DropdownFieldElement {
                return SectionElement($0)
            }
            return $0
        }
        self.init(elements: elements)
    }
    
    static func makeBancontact(configuration: Configuration) -> FormElement {
        let name = TextFieldElement.Address.makeName()
        if configuration.canSave {
            let email = TextFieldElement.Address.makeEmail()
            let mandate = StaticElement(view: SepaMandateView(merchantDisplayName: configuration.merchantDisplayName))
            let save = SaveCheckboxElement(didToggle: { selected in
                email.isOptional = !selected
                mandate.isHidden = !selected
            })
            return FormElement([name, email, save, mandate])
        } else {
            return FormElement([name])
        }
    }
    
    static func makeAlipay() -> FormElement {
        return FormElement(elements: [])
    }
    
    static func makeSofort(configuration: Configuration) -> FormElement {
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
        if configuration.canSave {
            let name = TextFieldElement.Address.makeName()
            let email = TextFieldElement.Address.makeEmail()
            let mandate = StaticElement(view: SepaMandateView(merchantDisplayName: configuration.merchantDisplayName))
            let save = SaveCheckboxElement(didToggle: { selected in
                name.isOptional = !selected
                email.isOptional = !selected
                mandate.isHidden = !selected
            })
            return FormElement([name, email, country, save, mandate])
        } else {
            return FormElement([country])
        }
    }
    
    static func makeIdeal(configuration: Configuration) -> FormElement {
        let name = TextFieldElement.Address.makeName()
        let banks = STPiDEALBank.allCases
        let bank = DropdownFieldElement(
            items: banks.map { $0.displayName },
            label: STPLocalizedString(
                "iDEAL Bank",
                "iDEAL bank section title for iDEAL form entry."
            )
        ) { params, selectedIndex in
            let idealParams = params.paymentMethodParams.iDEAL ?? STPPaymentMethodiDEALParams()
            idealParams.bankName = banks[selectedIndex].name
            params.paymentMethodParams.iDEAL = idealParams
            return params
        }
        if configuration.canSave {
            let email = TextFieldElement.Address.makeEmail()
            let mandate = StaticElement(view: SepaMandateView(merchantDisplayName: configuration.merchantDisplayName))
            let save = SaveCheckboxElement(didToggle: { selected in
                email.isOptional = !selected
                mandate.isHidden = !selected
            })
            return FormElement([name, bank, email, save, mandate])
        } else {
            return FormElement([name, bank])
        }
    }
    
    static func makeSepa(configuration: Configuration) -> FormElement {
        let iban = TextFieldElement.makeIBAN()
        let name = TextFieldElement.Address.makeName()
        let email = TextFieldElement.Address.makeEmail()
        let mandate = StaticElement(view: SepaMandateView(merchantDisplayName: configuration.merchantDisplayName))
        let save = SaveCheckboxElement(didToggle: { selected in
            email.isOptional = !selected
            mandate.isHidden = !selected
        })
        if configuration.canSave {
            return FormElement([name, email, iban, save, mandate])
        } else {
            return FormElement([name, email, iban])
        }
    }
}
