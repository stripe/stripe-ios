//
//  FormElement+Factory.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

struct FormElementFactory {
    enum SaveMode {
        /// We can't save the PaymentMethod. e.g., Payment mode without a customer
        case none
        /// The customer chooses whether or not to save the PaymentMethod. e.g., Payment mode
        case userSelectable
        /// `setup_future_usage` is set on the PaymentIntent or Setup mode
        case merchantRequired
    }
    let saveMode: SaveMode
    let intent: Intent
    let configuration: PaymentSheet.Configuration

    init(intent: Intent, configuration: PaymentSheet.Configuration) {
        switch intent {
        case let .paymentIntent(paymentIntent):
            if configuration.customer == nil {
                saveMode = .none
            } else if paymentIntent.setupFutureUsage != .none {
                saveMode =  .merchantRequired
            } else {
                saveMode = .userSelectable
            }
        case .setupIntent:
            saveMode = .merchantRequired
        }
        self.intent = intent
        self.configuration = configuration
    }
    
    // MARK: - DRY Helper funcs
    
    func makeName() -> TextFieldElement {
        TextFieldElement.Address.makeName(defaultValue: configuration.defaultBillingDetails.name)
    }
    
    func makeEmail() -> TextFieldElement {
        TextFieldElement.Address.makeEmail(defaultValue: configuration.defaultBillingDetails.email)
    }
    
    func makeMandate() -> StaticElement {
        StaticElement(view: SepaMandateView(merchantDisplayName: configuration.merchantDisplayName))
    }
    
    // MARK: - PaymentMethod form definitions

    func makeBancontact() -> FormElement {
        let name = makeName()
        let email = makeEmail()
        let mandate = makeMandate()
        let save = SaveCheckboxElement() { selected in
            email.isOptional = !selected
            mandate.isHidden = !selected
        }
        switch saveMode {
        case .none:
            return FormElement([name])
        case .userSelectable:
            return FormElement([name, email, save, mandate])
        case .merchantRequired:
            return FormElement([name, email, mandate])
        }
    }
    
    func makeSofort() -> FormElement {
        let locale = Locale.current
        let countryCodes = locale.sortedByTheirLocalizedNames(
            /// A hardcoded list of countries that support Sofort
            ["AT", "BE", "DE", "IT", "NL", "ES"]
        )
        let country = DropdownFieldElement(
            label: String.Localized.country,
            countryCodes: countryCodes,
            defaultCountry: configuration.defaultBillingDetails.address.country
        ) { params, index in
            let sofortParams = params.paymentMethodParams.sofort ?? STPPaymentMethodSofortParams()
            sofortParams.country = countryCodes[index]
            params.paymentMethodParams.sofort = sofortParams
            return params
        }
        let name = makeName()
        let email = makeEmail()
        let mandate = makeMandate()
        let save = SaveCheckboxElement(didToggle: { selected in
            name.isOptional = !selected
            email.isOptional = !selected
            mandate.isHidden = !selected
        })
        switch saveMode {
        case .none:
            return FormElement([country])
        case .userSelectable:
            return FormElement([name, email, country, save, mandate])
        case .merchantRequired:
            return FormElement([name, email, country, mandate])
        }
    }
    
    func makeIdeal() -> FormElement {
        let name = makeName()
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
        let email = makeEmail()
        let mandate = makeMandate()
        let save = SaveCheckboxElement(didToggle: { selected in
            email.isOptional = !selected
            mandate.isHidden = !selected
        })
        switch saveMode {
        case .none:
            return FormElement([name, bank])
        case .userSelectable:
            return FormElement([name, bank, email, save, mandate])
        case .merchantRequired:
            return FormElement([name, bank, email, mandate])
        }
    }
    
    func makeSepa() -> FormElement {
        let iban = TextFieldElement.makeIBAN()
        let name = makeName()
        let email = makeEmail()
        let mandate = makeMandate()
        let save = SaveCheckboxElement(didToggle: { selected in
            email.isOptional = !selected
            mandate.isHidden = !selected
        })
        let address = SectionElement.makeBillingAddress(defaults: configuration.defaultBillingDetails.address)
        switch saveMode {
        case .none:
            return FormElement([name, email, iban, address])
        case .userSelectable:
            return FormElement([name, email, iban, address, save, mandate])
        case .merchantRequired:
            return FormElement([name, email, iban, address, mandate])
        }
    }
    
    func makeGiropay() -> FormElement {
        return FormElement([makeName()])
    }
    
    func makeEPS() -> FormElement {
        return FormElement([makeName()])
    }
    
    func makeP24() -> FormElement {
        return FormElement([makeName(), makeEmail()])
    }
    
    func makeAfterpayClearpay() -> FormElement {
        guard case let .paymentIntent(paymentIntent) = intent else {
            assertionFailure()
            return FormElement(elements: [])
        }
        let priceBreakdownView = StaticElement(
            view: AfterpayPriceBreakdownView(amount: paymentIntent.amount, currency: paymentIntent.currency)
        )
        let billingAddressSection = SectionElement.makeBillingAddress()
        return FormElement([priceBreakdownView, makeName(), makeEmail(), billingAddressSection])
    }
}

fileprivate extension FormElement {
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
}
