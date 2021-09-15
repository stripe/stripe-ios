//
//  PaymentSheetFormFactory.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeCore
import SwiftUI

/**
 This class creates a FormElement for a given payment method type and binds the FormElement's field values to an
 `IntentConfirmParams`.
 */
class PaymentSheetFormFactory {
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
    
    func makeForm(for type: STPPaymentMethodType) -> PaymentMethodElement {
        if type == .card {
            return CardDetailsEditView(
                shouldDisplaySaveThisPaymentMethodCheckbox: saveMode == .userSelectable,
                configuration: configuration
            )
        }
        let formElements: [Element] = {
            switch type {
            case .bancontact:
                return makeBancontact()
            case .iDEAL:
                return makeIdeal()
            case .sofort:
                return makeSofort()
            case .SEPADebit:
                return makeSepa()
            case .giropay:
                return makeGiropay()
            case .EPS:
                return makeEPS()
            case .przelewy24:
                return makeP24()
            case .afterpayClearpay:
                return makeAfterpayClearpay()
            default:
                fatalError()
            }
        }()
        return FormElement(formElements)
    }
    
    // MARK: - DRY Helper funcs
    
    func makeName() -> PaymentMethodElementWrapper<TextFieldElement> {
        let element = TextFieldElement.Address.makeName(defaultValue: configuration.defaultBillingDetails.name)
        return PaymentMethodElementWrapper(element) { textField, params in
            params.paymentMethodParams.nonnil_billingDetails.name = textField.text
            return params
        }
    }
    
    func makeEmail() -> PaymentMethodElementWrapper<TextFieldElement>  {
        let element = TextFieldElement.Address.makeEmail(defaultValue: configuration.defaultBillingDetails.email)
        return PaymentMethodElementWrapper(element) { textField, params in
            params.paymentMethodParams.nonnil_billingDetails.email = textField.text
            return params
        }
    }
    
    func makeMandate() -> StaticElement {
        return StaticElement(view: SepaMandateView(merchantDisplayName: configuration.merchantDisplayName))
    }
    
    func makeSaveCheckbox(didToggle: @escaping ((Bool) -> ())) -> PaymentMethodElementWrapper<SaveCheckboxElement> {
        let element = SaveCheckboxElement(didToggle: didToggle)
        return PaymentMethodElementWrapper(element) { checkbox, params in
            params.savePaymentMethod = checkbox.checkboxButton.isSelected
            return params
        }
    }

    // MARK: - PaymentMethod form definitions

    func makeBancontact() -> [PaymentMethodElement] {
        let name = makeName()
        let email = makeEmail()
        let mandate = makeMandate()
        let save = makeSaveCheckbox() { selected in
            email.element.isOptional = !selected
            mandate.isHidden = !selected
        }
        
        switch saveMode {
        case .none:
            return [name]
        case .userSelectable:
            return [name, email, save, mandate]
        case .merchantRequired:
            return [name, email, mandate]
        }
    }
    
    func makeSofort() -> [PaymentMethodElement] {
        let locale = Locale.current
        let countryCodes = locale.sortedByTheirLocalizedNames(
            /// A hardcoded list of countries that support Sofort
            ["AT", "BE", "DE", "IT", "NL", "ES"]
        )
        let country = PaymentMethodElementWrapper(DropdownFieldElement(
            label: String.Localized.country,
            countryCodes: countryCodes,
            defaultCountry: configuration.defaultBillingDetails.address.country,
            locale: locale
        )) { dropdown, params in
            let sofortParams = params.paymentMethodParams.sofort ?? STPPaymentMethodSofortParams()
            sofortParams.country = countryCodes[dropdown.selectedIndex]
            params.paymentMethodParams.sofort = sofortParams
            return params
        }
        let name = makeName()
        let email = makeEmail()
        let mandate = makeMandate()
        let save = makeSaveCheckbox(didToggle: { selected in
            name.element.isOptional = !selected
            email.element.isOptional = !selected
            mandate.isHidden = !selected
        })
        switch saveMode {
        case .none:
            return [country]
        case .userSelectable:
            return [name, email, country, save, mandate]
        case .merchantRequired:
            return [name, email, country, mandate]
        }
    }

    func makeIdeal() -> [PaymentMethodElement] {
        let name = makeName()
        let banks = STPiDEALBank.allCases
        let items = banks.map { $0.displayName } + [String.Localized.other]
        let bank = PaymentMethodElementWrapper(DropdownFieldElement(
            items: items,
            label: String.Localized.ideal_bank
        )) { bank, params in
            let idealParams = params.paymentMethodParams.iDEAL ?? STPPaymentMethodiDEALParams()
            idealParams.bankName = banks.stp_boundSafeObject(at: bank.selectedIndex)?.name
            params.paymentMethodParams.iDEAL = idealParams
            return params
        }
        let email = makeEmail()
        let mandate = makeMandate()
        let save = makeSaveCheckbox(didToggle: { selected in
            email.element.isOptional = !selected
            mandate.isHidden = !selected
        })
        switch saveMode {
        case .none:
            return [name, bank]
        case .userSelectable:
            return [name, bank, email, save, mandate]
        case .merchantRequired:
            return [name, bank, email, mandate]
        }
    }

    func makeSepa() -> [PaymentMethodElement] {
        let iban = PaymentMethodElementWrapper(TextFieldElement.makeIBAN()) { iban, params in
            let sepa = params.paymentMethodParams.sepaDebit ?? STPPaymentMethodSEPADebitParams()
            sepa.iban = iban.text
            params.paymentMethodParams.sepaDebit = sepa
            return params
        }
        let name = makeName()
        let email = makeEmail()
        let mandate = makeMandate()
        let save = makeSaveCheckbox(didToggle: { selected in
            email.element.isOptional = !selected
            mandate.isHidden = !selected
        })
        let address = SectionElement.makeBillingAddress(defaults: configuration.defaultBillingDetails.address)
        switch saveMode {
        case .none:
            return [name, email, iban, address]
        case .userSelectable:
            return [name, email, iban, address, save, mandate]
        case .merchantRequired:
            return [name, email, iban, address, mandate]
        }
    }

    func makeGiropay() -> [PaymentMethodElement] {
        return [makeName()]
    }

    func makeEPS() -> [PaymentMethodElement] {
        return [makeName()]
    }

    func makeP24() -> [PaymentMethodElement] {
        return [makeName(), makeEmail()]
    }

    func makeAfterpayClearpay() -> [PaymentMethodElement] {
        guard case let .paymentIntent(paymentIntent) = intent else {
            assertionFailure()
            return []
        }
        let priceBreakdownView = StaticElement(
            view: AfterpayPriceBreakdownView(amount: paymentIntent.amount, currency: paymentIntent.currency)
        )
        let billingAddressSection = SectionElement.makeBillingAddress()
        return [priceBreakdownView, makeName(), makeEmail(), billingAddressSection]
    }
}

fileprivate extension FormElement {
    /// Conveniently nests single TextField and DropdownFields in a Section
    convenience init(_ autoSectioningElements: [Element]) {
        let elements: [Element] = autoSectioningElements.map {
            if $0 is PaymentMethodElementWrapper<TextFieldElement> || $0 is PaymentMethodElementWrapper<DropdownFieldElement> {
                return SectionElement($0)
            }
            return $0
        }
        self.init(elements: elements)
    }
}
