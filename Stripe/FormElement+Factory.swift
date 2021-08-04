//
//  FormElement+Factory.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension FormElement {
    struct Configuration {
        enum SaveMode {
            /// We can't save the PaymentMethod. e.g., Payment mode without a customer
            case none
            /// The customer chooses whether or not to save the PaymentMethod. e.g., Payment mode
            case userSelectable
            /// `setup_future_usage` is set on the PaymentIntent or Setup mode
            case merchantRequired
        }
        let saveMode: SaveMode
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
        let email = TextFieldElement.Address.makeEmail()
        let mandate = StaticElement(view: SepaMandateView(merchantDisplayName: configuration.merchantDisplayName))
        let save = SaveCheckboxElement() { selected in
            email.isOptional = !selected
            mandate.isHidden = !selected
        }
        switch configuration.saveMode {
        case .none:
            return FormElement([name])
        case .userSelectable:
            return FormElement([name, email, save, mandate])
        case .merchantRequired:
            return FormElement([name, email, mandate])
        }
    }
    
    static func makeAlipay() -> FormElement {
        return FormElement(elements: [])
    }
    
    static func makeSofort(configuration: Configuration) -> FormElement {
        let locale = Locale.current
        let countryCodes = locale.sortedByTheirLocalizedNames(
            /// A hardcoded list of countries that support Sofort
            ["AT", "BE", "DE", "IT", "NL", "ES"]
        )
        let country = DropdownFieldElement(
            label: .Localized.country,
            countryCodes: countryCodes
        ) { params, index in
            let sofortParams = params.paymentMethodParams.sofort ?? STPPaymentMethodSofortParams()
            sofortParams.country = countryCodes[index]
            params.paymentMethodParams.sofort = sofortParams
            return params
        }
        let name = TextFieldElement.Address.makeName()
        let email = TextFieldElement.Address.makeEmail()
        let mandate = StaticElement(view: SepaMandateView(merchantDisplayName: configuration.merchantDisplayName))
        let save = SaveCheckboxElement(didToggle: { selected in
            name.isOptional = !selected
            email.isOptional = !selected
            mandate.isHidden = !selected
        })
        switch configuration.saveMode {
        case .none:
            return FormElement([country])
        case .userSelectable:
            return FormElement([name, email, country, save, mandate])
        case .merchantRequired:
            return FormElement([name, email, country, mandate])
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
        let email = TextFieldElement.Address.makeEmail()
        let mandate = StaticElement(view: SepaMandateView(merchantDisplayName: configuration.merchantDisplayName))
        let save = SaveCheckboxElement(didToggle: { selected in
            email.isOptional = !selected
            mandate.isHidden = !selected
        })
        switch configuration.saveMode {
        case .none:
            return FormElement([name, bank])
        case .userSelectable:
            return FormElement([name, bank, email, save, mandate])
        case .merchantRequired:
            return FormElement([name, bank, email, mandate])
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
        switch configuration.saveMode {
        case .none:
            return FormElement([name, email, iban])
        case .userSelectable:
            return FormElement([name, email, iban, save, mandate])
        case .merchantRequired:
            return FormElement([name, email, iban, mandate])
        }
    }
}
