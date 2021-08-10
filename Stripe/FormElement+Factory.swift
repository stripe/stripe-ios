//
//  FormElement+Factory.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension Element {
    // MARK: - DRY Helper funcs
    static func Name() -> TextFieldElement { TextFieldElement.Address.makeName() }
    static func Email() -> TextFieldElement { TextFieldElement.Address.makeEmail() }
    static func Mandate(_ name: String) -> StaticElement {
        StaticElement(view: SepaMandateView(merchantDisplayName: name))
    }
}

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
    convenience init(_ autoSectioningElements: [Element]) {
        let elements: [Element] = autoSectioningElements.map {
            if $0 is TextFieldElement || $0 is DropdownFieldElement {
                return SectionElement($0)
            }
            return $0
        }
        self.init(elements: elements)
    }
    
    static func makeBancontact(configuration: Configuration) -> FormElement {
        let name = Name()
        let email = Email()
        let mandate = Mandate(configuration.merchantDisplayName)
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
    
    static func makeSofort(configuration: Configuration) -> FormElement {
        let locale = Locale.current
        let countryCodes = locale.sortedByTheirLocalizedNames(
            /// A hardcoded list of countries that support Sofort
            ["AT", "BE", "DE", "IT", "NL", "ES"]
        )
        let country = DropdownFieldElement(
            label: String.Localized.country,
            countryCodes: countryCodes
        ) { params, index in
            let sofortParams = params.paymentMethodParams.sofort ?? STPPaymentMethodSofortParams()
            sofortParams.country = countryCodes[index]
            params.paymentMethodParams.sofort = sofortParams
            return params
        }
        let name = Name()
        let email = Email()
        let mandate = Mandate(configuration.merchantDisplayName)
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
        let name = Name()
        let banks = STPiDEALBank.allCases
        let items = banks.map { $0.displayName } + [String.Localized.other]
        let bank = DropdownFieldElement(
            items: items,
            label: String.Localized.ideal_bank
        ) { params, selectedIndex in
            let idealParams = params.paymentMethodParams.iDEAL ?? STPPaymentMethodiDEALParams()
            idealParams.bankName = banks.stp_boundSafeObject(at: selectedIndex)?.name
            params.paymentMethodParams.iDEAL = idealParams
            return params
        }
        let email = Email()
        let mandate = Mandate(configuration.merchantDisplayName)
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
        let name = Name()
        let email = Email()
        let mandate = Mandate(configuration.merchantDisplayName)
        let save = SaveCheckboxElement(didToggle: { selected in
            email.isOptional = !selected
            mandate.isHidden = !selected
        })
        let address = SectionElement.makeBillingAddress()
        switch configuration.saveMode {
        case .none:
            return FormElement([name, email, iban, address])
        case .userSelectable:
            return FormElement([name, email, iban, address, save, mandate])
        case .merchantRequired:
            return FormElement([name, email, iban, address, mandate])
        }
    }
    
    static func makeGiropay(configuration: Configuration) -> FormElement {
        return FormElement([Name()])
    }
    
    static func makeEPS(configuration: Configuration) -> FormElement {
        return FormElement([Name()])
    }
    
    static func makeP24(configuration: Configuration) -> FormElement {
        return FormElement([Name(), Email()])
    }
}
