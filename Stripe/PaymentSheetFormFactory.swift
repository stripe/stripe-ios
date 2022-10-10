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
@_spi(STP) import StripeUICore

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
    let paymentMethod: PaymentSheet.PaymentMethodType
    let intent: Intent
    let configuration: PaymentSheet.Configuration
    let addressSpecProvider: AddressSpecProvider
    let offerSaveToLinkWhenSupported: Bool
    let linkAccount: PaymentSheetLinkAccount?

    var canSaveToLink: Bool {
        return (
            intent.supportsLink &&
            paymentMethod == .card &&
            saveMode != .merchantRequired
        )
    }

    var theme: ElementsUITheme {
        return configuration.appearance.asElementsTheme
    }

    init(
        intent: Intent,
        configuration: PaymentSheet.Configuration,
        paymentMethod: PaymentSheet.PaymentMethodType,
        addressSpecProvider: AddressSpecProvider = .shared,
        offerSaveToLinkWhenSupported: Bool = false,
        linkAccount: PaymentSheetLinkAccount? = nil
    ) {
        switch intent {
        case let .paymentIntent(paymentIntent):
            let merchantRequiresSave = paymentIntent.setupFutureUsage != .none
            let hasCustomer = configuration.customer != nil
            let isPaymentMethodSaveable = PaymentSheet.PaymentMethodType.supportsSaveAndReuse(paymentMethod: paymentMethod, configuration: configuration, intent: intent)
            switch (merchantRequiresSave, hasCustomer, isPaymentMethodSaveable) {
            case (true, _, _):
                saveMode = .merchantRequired
            case (false, true, true):
                saveMode = .userSelectable
            case (false, true, false):
                fallthrough
            case (false, false, _):
                saveMode = .none
            }
        case .setupIntent:
            saveMode = .merchantRequired
        }
        self.intent = intent
        self.configuration = configuration
        self.paymentMethod = paymentMethod
        self.addressSpecProvider = addressSpecProvider
        self.offerSaveToLinkWhenSupported = offerSaveToLinkWhenSupported
        self.linkAccount = linkAccount
    }
    
    func make() -> PaymentMethodElement {
        // We have two ways to create the form for a payment method
        // 1. Custom, one-off forms
        if paymentMethod == .card {
            return makeCard(theme: theme)
        } else if paymentMethod == .linkInstantDebit {
            return ConnectionsElement()
        } else if paymentMethod == .USBankAccount {
            return makeUSBankAccount(merchantName: configuration.merchantDisplayName)
        } else if paymentMethod == .UPI {
            return makeUPI()
        }

        // 2. Element-based forms defined in JSON
        guard let spec = specFromJSONProvider() else {
            fatalError()
        }
        return makeFormElementFromSpec(spec: spec)
    }
}

extension PaymentSheetFormFactory {
    // MARK: - DRY Helper funcs
    
    func makeName(label: String? = nil, apiPath: String? = nil) -> PaymentMethodElementWrapper<TextFieldElement> {
        let element = TextFieldElement.makeName(label: label, defaultValue: configuration.defaultBillingDetails.name, theme: theme)
        return PaymentMethodElementWrapper(element) { textField, params in
            if let apiPath = apiPath {
                params.paymentMethodParams.additionalAPIParameters[apiPath] = textField.text
            } else {
                params.paymentMethodParams.nonnil_billingDetails.name = textField.text
            }
            return params
        }
    }

    func makeEmail(apiPath: String? = nil) -> PaymentMethodElementWrapper<TextFieldElement>  {
        let element = TextFieldElement.makeEmail(defaultValue: configuration.defaultBillingDetails.email, theme: theme)
        return PaymentMethodElementWrapper(element) { textField, params in
            if let apiPath = apiPath {
                params.paymentMethodParams.additionalAPIParameters[apiPath] = textField.text
            } else {
                params.paymentMethodParams.nonnil_billingDetails.email = textField.text
            }
            return params
        }
    }

    func makeBSB(apiPath: String? = nil) -> PaymentMethodElementWrapper<TextFieldElement> {
        let element = TextFieldElement.Account.makeBSB(defaultValue: nil, theme: theme)
        return PaymentMethodElementWrapper(element) { textField, params in
            let bsbNumberText = BSBNumber(number: textField.text).bsbNumberText()
            if let apiPath = apiPath {
                params.paymentMethodParams.additionalAPIParameters[apiPath] = bsbNumberText
            } else {
                params.paymentMethodParams.nonnil_auBECSDebit.bsbNumber = bsbNumberText
            }
            return params
        }
    }

    func makeAUBECSAccountNumber(apiPath: String? = nil) -> PaymentMethodElementWrapper<TextFieldElement> {
        let element = TextFieldElement.Account.makeAUBECSAccountNumber(defaultValue: nil, theme: theme)
        return PaymentMethodElementWrapper(element) { textField, params in
            if let apiPath = apiPath {
                params.paymentMethodParams.additionalAPIParameters[apiPath] = textField.text
            } else {
                params.paymentMethodParams.nonnil_auBECSDebit.accountNumber = textField.text
            }
            return params
        }
    }

    func makeAUBECSMandate() -> StaticElement {
        return StaticElement(view: AUBECSLegalTermsView(configuration: configuration))
    }

    func makeSepaMandate() -> StaticElement {
        return StaticElement(view: SepaMandateView(merchantDisplayName: configuration.merchantDisplayName, theme: theme))
    }
    
    func makeSaveCheckbox(
        label: String = String.Localized.save_for_future_payments,
        didToggle: ((Bool) -> ())? = nil
    ) -> PaymentMethodElementWrapper<CheckboxElement> {
        let element = CheckboxElement(
            theme: configuration.appearance.asElementsTheme,
            label: label,
            isSelectedByDefault: configuration.savePaymentMethodOptInBehavior.isSelectedByDefault,
            didToggle: didToggle
        )
        return PaymentMethodElementWrapper(element) { checkbox, params in
            if !checkbox.checkboxButton.isHidden {
                params.shouldSavePaymentMethod = checkbox.checkboxButton.isSelected
            }
            return params
        }
    }
    
    func makeBillingAddressSection(
        collectionMode: AddressSectionElement.CollectionMode = .all,
        countries: [String]?
    ) -> PaymentMethodElementWrapper<AddressSectionElement> {
        let displayBillingSameAsShippingCheckbox: Bool
        let defaultAddress: AddressSectionElement.AddressDetails
        if let shippingDetails = configuration.shippingDetails() {
            // If defaultBillingDetails and shippingDetails are both populated, prefer defaultBillingDetails
            displayBillingSameAsShippingCheckbox = configuration.defaultBillingDetails == .init()
            defaultAddress = displayBillingSameAsShippingCheckbox ? .init(shippingDetails) : configuration.defaultBillingDetails.address.addressSectionDefaults
        } else {
            displayBillingSameAsShippingCheckbox = false
            defaultAddress = configuration.defaultBillingDetails.address.addressSectionDefaults
        }
        let section = AddressSectionElement(
            title: String.Localized.billing_address,
            countries: countries,
            addressSpecProvider: addressSpecProvider,
            defaults: defaultAddress,
            collectionMode: collectionMode,
            additionalFields: .init(billingSameAsShippingCheckbox: displayBillingSameAsShippingCheckbox ? .enabled(isOptional: false) : .disabled),
            theme: theme
        )
        return PaymentMethodElementWrapper(section) { section, params in
            guard case .valid = section.validationState else {
                return nil
            }
            if let line1 = section.line1 {
                params.paymentMethodParams.nonnil_billingDetails.nonnil_address.line1 = line1.text
            }
            if let line2 = section.line2 {
                params.paymentMethodParams.nonnil_billingDetails.nonnil_address.line2 = line2.text
            }
            if let city = section.city {
                params.paymentMethodParams.nonnil_billingDetails.nonnil_address.city = city.text
            }
            if let state = section.state {
                params.paymentMethodParams.nonnil_billingDetails.nonnil_address.state = state.rawData
            }
            if let postalCode = section.postalCode {
                params.paymentMethodParams.nonnil_billingDetails.nonnil_address.postalCode = postalCode.text
            }
            params.paymentMethodParams.nonnil_billingDetails.nonnil_address.country = section.selectedCountryCode

            return params
        }
    }

    // MARK: - PaymentMethod form definitions

    func makeUSBankAccount(merchantName: String) -> PaymentMethodElement {
        let isSaving = BoolReference()
        let saveCheckbox = makeSaveCheckbox(
            label: String(format: STPLocalizedString("Save this account for future %@ payments", "Prompt next to checkbox to save bank account."), merchantName)) { value in
                isSaving.value = value
            }
        let shouldDisplaySaveCheckbox: Bool = saveMode == .userSelectable && !canSaveToLink
        isSaving.value = shouldDisplaySaveCheckbox ? configuration.savePaymentMethodOptInBehavior.isSelectedByDefault : saveMode == .merchantRequired
        return USBankAccountPaymentMethodElement(titleElement: makeUSBankAccountCopyLabel(),
                                                 nameElement: makeName(),
                                                 emailElement: makeEmail(),
                                                 checkboxElement: shouldDisplaySaveCheckbox ? saveCheckbox : nil,
                                                 savingAccount: isSaving,
                                                 merchantName: merchantName,
                                                 theme: theme)
    }

    func makeCountry(countryCodes: [String]?, apiPath: String? = nil) -> PaymentMethodElement {
        let locale = Locale.current
        let resolvedCountryCodes = countryCodes ?? addressSpecProvider.countries
        let country = PaymentMethodElementWrapper(DropdownFieldElement.Address.makeCountry(
            label: String.Localized.country,
            countryCodes: resolvedCountryCodes,
            theme: theme,
            defaultCountry: configuration.defaultBillingDetails.address.country,
            locale: locale
        )) { dropdown, params in
            if let apiPath = apiPath {
                params.paymentMethodParams.additionalAPIParameters[apiPath] = resolvedCountryCodes[dropdown.selectedIndex]
            } else {
                params.paymentMethodParams.nonnil_billingDetails.nonnil_address.country = resolvedCountryCodes[dropdown.selectedIndex]
            }
            return params
        }
        return country
    }

    func makeIban(apiPath: String? = nil) -> PaymentMethodElementWrapper<TextFieldElement> {
        return PaymentMethodElementWrapper(TextFieldElement.makeIBAN(theme: theme)) { iban, params in
            if let apiPath = apiPath  {
                params.paymentMethodParams.additionalAPIParameters[apiPath] = iban.text
            } else {
                let sepa = params.paymentMethodParams.sepaDebit ?? STPPaymentMethodSEPADebitParams()
                sepa.iban = iban.text
                params.paymentMethodParams.sepaDebit = sepa
            }
            return params
        }
    }

    func makeAfterpayClearpayHeader() -> StaticElement? {
        guard case let .paymentIntent(paymentIntent) = intent else {
            assertionFailure()
            return nil
        }
        return StaticElement(
            view: AfterpayPriceBreakdownView(amount: paymentIntent.amount, currency: paymentIntent.currency, theme: theme)
        )
    }

    func makeKlarnaCountry(apiPath: String? = nil) -> PaymentMethodElement? {
        guard case let .paymentIntent(paymentIntent) = intent else {
            assertionFailure("Klarna only be used with a PaymentIntent")
            return nil
        }

        let countryCodes = Locale.current.sortedByTheirLocalizedNames(
            KlarnaHelper.availableCountries(currency: paymentIntent.currency)
        )
        let country = PaymentMethodElementWrapper(DropdownFieldElement.Address.makeCountry(
            label: String.Localized.country,
            countryCodes: countryCodes,
            theme: theme,
            defaultCountry: configuration.defaultBillingDetails.address.country,
            locale: Locale.current
        )) { dropdown, params in
            let countryCode = countryCodes[dropdown.selectedIndex]
            if let apiPath = apiPath {
                params.paymentMethodParams.additionalAPIParameters[apiPath] = countryCode
            } else {
                let address = STPPaymentMethodAddress()
                address.country = countryCode
                params.paymentMethodParams.nonnil_billingDetails.address = address
            }
            return params
        }
        return country
    }

    func makeKlarnaCopyLabel() -> StaticElement {
        let text = KlarnaHelper.canBuyNow()
        ? STPLocalizedString("Buy now or pay later with Klarna.", "Klarna buy now or pay later copy")
        : STPLocalizedString("Pay later with Klarna.", "Klarna pay later copy")
        return makeSectionTitleLabelWith(text: text)
    }

    private func makeUSBankAccountCopyLabel() -> StaticElement {
        return makeSectionTitleLabelWith(text: STPLocalizedString("Pay with your bank account in just a few steps.",
                                                                  "US Bank Account copy title for Mobile payment element form"))
    }

    func makeSectionTitleLabelWith(text: String) -> StaticElement {
        let label = UILabel()
        label.text = text
        label.font = theme.fonts.subheadline
        label.textColor = theme.colors.secondaryText
        label.numberOfLines = 0
        return StaticElement(view: label)
    }
}

// MARK: - Extension helpers

extension FormElement {
    /// Conveniently nests single TextField and DropdownFields in a Section
    convenience init(autoSectioningElements: [Element], theme: ElementsUITheme = .default) {
        let elements: [Element] = autoSectioningElements.map {
            if $0 is PaymentMethodElementWrapper<TextFieldElement> || $0 is PaymentMethodElementWrapper<DropdownFieldElement> {
                return SectionElement($0, theme: theme)
            }
            return $0
        }
        self.init(elements: elements, theme: theme)
    }
}

extension STPPaymentMethodBillingDetails {
    var nonnil_address: STPPaymentMethodAddress {
        guard let address = address else {
            let address = STPPaymentMethodAddress()
            self.address = address
            return address
        }
        return address
    }
}

extension AddressSectionElement.AddressDetails {
    init(_ addressDetails: AddressViewController.AddressDetails) {
        self.init(name: addressDetails.name, phone: addressDetails.phone, address: .init(addressDetails.address))
    }
}

extension AddressSectionElement.AddressDetails.Address {
    init(_ address: AddressViewController.AddressDetails.Address) {
        self.init(
            city: address.city,
            country: address.country,
            line1: address.line1,
            line2: address.line2,
            postalCode: address.postalCode,
            state: address.state
        )
    }
}


private extension PaymentSheet.Address {
    var addressSectionDefaults: AddressSectionElement.AddressDetails {
        return .init(address: .init(
            city: city,
            country: country,
            line1: line1,
            line2: line2,
            postalCode: postalCode,
            state: state
        ))
    }
}

extension PaymentSheet.Appearance {

    /// Creates an `ElementsUITheme` based on this PaymentSheet appearance
    var asElementsTheme: ElementsUITheme {
        var theme = ElementsUITheme.default

        var colors = ElementsUITheme.Color()
        colors.primary = self.colors.primary
        colors.parentBackground = self.colors.background
        colors.background = self.colors.componentBackground
        colors.bodyText = self.colors.text
        colors.border = self.colors.componentBorder
        colors.divider = self.colors.componentDivider
        colors.textFieldText = self.colors.componentText
        colors.secondaryText = self.colors.textSecondary
        colors.placeholderText = self.colors.componentPlaceholderText
        colors.danger = self.colors.danger

        theme.borderWidth = borderWidth
        theme.cornerRadius = cornerRadius
        theme.shadow = shadow.asElementThemeShadow

        var fonts = ElementsUITheme.Font()
        fonts.subheadline = scaledFont(for: font.base.regular, style: .subheadline, maximumPointSize: 20)
        fonts.subheadlineBold = scaledFont(for: font.base.bold, style: .subheadline, maximumPointSize: 20)
        fonts.sectionHeader = scaledFont(for: font.base.medium, style: .footnote, maximumPointSize: 18)
        fonts.caption = scaledFont(for: font.base.regular, style: .caption1, maximumPointSize: 20)
        fonts.footnote = scaledFont(for: font.base.regular, style: .footnote, maximumPointSize: 20)
        fonts.footnoteEmphasis = scaledFont(for: font.base.medium, style: .footnote, maximumPointSize: 20)

        theme.colors = colors
        theme.fonts = fonts

        return theme
    }
}

extension PaymentSheet.Appearance.Shadow {

    /// Creates an `ElementsUITheme.Shadow` based on this PaymentSheet appearance shadow
    var asElementThemeShadow: ElementsUITheme.Shadow? {
        return ElementsUITheme.Shadow(color: color, opacity: opacity, offset: offset, radius: radius)
    }

    init(elementShadow: ElementsUITheme.Shadow) {
        self.color = elementShadow.color
        self.opacity = elementShadow.opacity
        self.offset = elementShadow.offset
        self.radius = elementShadow.radius
    }
}
