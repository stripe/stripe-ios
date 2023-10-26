//
//  PaymentSheetFormFactory.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 6/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import SwiftUI
import UIKit

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
    let configuration: PaymentSheetFormFactoryConfig
    let addressSpecProvider: AddressSpecProvider
    let offerSaveToLinkWhenSupported: Bool
    let linkAccount: PaymentSheetLinkAccount?
    let previousCustomerInput: IntentConfirmParams?

    let supportsLinkCard: Bool
    let isPaymentIntent: Bool
    let currency: String?
    let amount: Int?
    let countryCode: String?
    let cardBrandChoiceEligible: Bool

    var canSaveToLink: Bool {
        // For Link private beta, only save cards in ".none" mode: If there is no Customer object.
        // We don't want to override the merchant's own "Save this card" checkbox.
        return (supportsLinkCard && paymentMethod == .stripe(.card) && saveMode == .none)
    }

    var theme: ElementsUITheme {
        return configuration.appearance.asElementsTheme
    }

    convenience init(
        intent: Intent,
        configuration: PaymentSheetFormFactoryConfig,
        paymentMethod: PaymentSheet.PaymentMethodType,
        previousCustomerInput: IntentConfirmParams? = nil,
        addressSpecProvider: AddressSpecProvider = .shared,
        offerSaveToLinkWhenSupported: Bool = false,
        linkAccount: PaymentSheetLinkAccount? = nil,
        cardBrandChoiceEligible: Bool = false
    ) {
        func saveModeFor(merchantRequiresSave: Bool) -> SaveMode {
            let hasCustomer = configuration.hasCustomer
            let supportsSaveForFutureUseCheckbox = paymentMethod.supportsSaveForFutureUseCheckbox()
            switch (merchantRequiresSave, hasCustomer, supportsSaveForFutureUseCheckbox) {
            case (true, _, _):
                return .merchantRequired
            case (false, true, true):
                return .userSelectable
            case (false, true, false):
                fallthrough
            case (false, false, _):
                return .none
            }
        }
        var saveMode: SaveMode
        switch intent {
        case let .paymentIntent(paymentIntent):
            saveMode = saveModeFor(merchantRequiresSave: paymentIntent.setupFutureUsage != .none)
        case .setupIntent:
            saveMode = .merchantRequired
        case .deferredIntent(_, let intentConfig):
            switch intentConfig.mode {
            case .payment(_, _, let setupFutureUsage, _):
                saveMode = saveModeFor(merchantRequiresSave: setupFutureUsage != .none)
            case .setup:
                saveMode = .merchantRequired
            }
        }
        self.init(configuration: configuration,
                  paymentMethod: paymentMethod,
                  previousCustomerInput: previousCustomerInput,
                  addressSpecProvider: addressSpecProvider,
                  offerSaveToLinkWhenSupported: offerSaveToLinkWhenSupported,
                  linkAccount: linkAccount,
                  cardBrandChoiceEligible: cardBrandChoiceEligible,
                  supportsLinkCard: intent.supportsLinkCard,
                  isPaymentIntent: intent.isPaymentIntent,
                  currency: intent.currency,
                  amount: intent.amount,
                  countryCode: intent.countryCode,
                  saveMode: saveMode)
    }

    required init(
        configuration: PaymentSheetFormFactoryConfig,
        paymentMethod: PaymentSheet.PaymentMethodType,
        previousCustomerInput: IntentConfirmParams? = nil,
        addressSpecProvider: AddressSpecProvider = .shared,
        offerSaveToLinkWhenSupported: Bool = false,
        linkAccount: PaymentSheetLinkAccount? = nil,
        cardBrandChoiceEligible: Bool = false,
        supportsLinkCard: Bool,
        isPaymentIntent: Bool,
        currency: String?,
        amount: Int?,
        countryCode: String?,
        saveMode: SaveMode
    ) {
        self.configuration = configuration
        self.paymentMethod = paymentMethod
        self.addressSpecProvider = addressSpecProvider
        self.offerSaveToLinkWhenSupported = offerSaveToLinkWhenSupported
        self.linkAccount = linkAccount
        // Restore the previous customer input if its the same type
        if previousCustomerInput?.paymentMethodType == paymentMethod {
            self.previousCustomerInput = previousCustomerInput
        } else {
            self.previousCustomerInput = nil
        }
        self.supportsLinkCard = supportsLinkCard
        self.isPaymentIntent = isPaymentIntent
        self.currency = currency
        self.amount = amount
        self.countryCode = countryCode
        self.saveMode = saveMode
        self.cardBrandChoiceEligible = cardBrandChoiceEligible
    }

    func make() -> PaymentMethodElement {
        guard case .stripe(let paymentMethod) = paymentMethod else {
            return makeExternalPayPal()
        }
        var additionalElements = [Element]()

        // We have two ways to create the form for a payment method
        // 1. Custom, one-off forms
        if paymentMethod == .card {
            return makeCard(cardBrandChoiceEligible: cardBrandChoiceEligible)
        } else if paymentMethod == .linkInstantDebit {
            return ConnectionsElement()
        } else if paymentMethod == .USBankAccount {
            return makeUSBankAccount(merchantName: configuration.merchantDisplayName)
        } else if paymentMethod == .UPI {
            return makeUPI()
        } else if paymentMethod == .cashApp && saveMode == .merchantRequired {
            // special case, display mandate for Cash App when setting up or pi+sfu
            additionalElements = [makeCashAppMandate()]
        } else if paymentMethod == .payPal && saveMode == .merchantRequired {
            // Paypal requires mandate when setting up
            additionalElements = [makePaypalMandate()]
        } else if paymentMethod == .revolutPay && saveMode == .merchantRequired {
            // special case, display mandate for revolutPay when setting up or pi+sfu
            additionalElements = [makeRevolutPayMandate()]
        } else if paymentMethod == .bancontact {
            return makeBancontact()
        } else if paymentMethod == .bacsDebit {
            return makeBacsDebit()
        } else if paymentMethod == .blik {
            return makeBLIK()
        } else if paymentMethod == .OXXO {
            return  makeOXXO()
        } else if paymentMethod == .konbini {
            return makeKonbini()
        } else if paymentMethod == .boleto {
            return makeBoleto()
        } else if paymentMethod == .swish {
            return makeSwish()
        }

        guard let spec = FormSpecProvider.shared.formSpec(for: paymentMethod.identifier) else {
            assertionFailure("Failed to get form spec!")
            return FormElement(elements: [], theme: theme)
        }
        if paymentMethod == .iDEAL {
            return makeiDEAL(spec: spec)
        } else if paymentMethod == .sofort {
            return makeSofort(spec: spec)
        }

        // 2. Element-based forms defined in JSON
        return makeFormElementFromSpec(spec: spec, additionalElements: additionalElements)
    }
}

extension PaymentSheetFormFactory {
    // MARK: - DRY Helper funcs

    /// For each field in PaymentSheet.BillingDetails, determines the default value by looking at (in order of preference):
    /// 1. the given API Path (only for name, email, and country fields),
    /// 2. `previousCustomerInput`
    /// 3. the merchant provided`configuration`
    func defaultBillingDetails(nameAPIPath: String? = nil, emailAPIPath: String? = nil, countryAPIPath: String? = nil) -> PaymentSheet.BillingDetails {
        let previous = previousCustomerInput?.paymentMethodParams.billingDetails
        let configuration = configuration.defaultBillingDetails
        var details = PaymentSheet.BillingDetails()
        details.name = getPreviousCustomerInput(for: nameAPIPath ?? "") ?? previous?.name ?? configuration.name
        details.phone = previous?.phone ?? configuration.phone
        details.email = getPreviousCustomerInput(for: emailAPIPath ?? "") ?? previous?.email ?? configuration.email
        details.address.line1 = previous?.address?.line1 ?? configuration.address.line1
        details.address.line2 = previous?.address?.line2 ?? configuration.address.line2
        details.address.city = previous?.address?.city ?? configuration.address.city
        details.address.state = previous?.address?.state ?? configuration.address.state
        details.address.postalCode = previous?.address?.postalCode ?? configuration.address.postalCode
        details.address.country = getPreviousCustomerInput(for: countryAPIPath ?? "") ?? previous?.address?.country ?? configuration.address.country
        return details
    }

    /// Fields generated from form specs i.e. LUXE can write their values to arbitrary keys (`apiPath`)  in `additionalAPIParameters`.
    func getPreviousCustomerInput(for apiPath: String?) -> String? {
        guard let apiPath = apiPath else {
            return nil
        }
        return previousCustomerInput?.paymentMethodParams.additionalAPIParameters[apiPath] as? String
    }

    func makeName(label: String? = nil, apiPath: String? = nil) -> PaymentMethodElementWrapper<TextFieldElement> {
        let defaultValue = defaultBillingDetails(nameAPIPath: apiPath).name
        let element = TextFieldElement.makeName(
            label: label,
            defaultValue: defaultValue,
            theme: theme
        )
        return PaymentMethodElementWrapper(element) { textField, params in
            if let apiPath = apiPath {
                params.paymentMethodParams.additionalAPIParameters[apiPath] = textField.text
            } else {
                params.paymentMethodParams.nonnil_billingDetails.name = textField.text
            }
            return params
        }
    }

    func makeEmail(apiPath: String? = nil) -> PaymentMethodElementWrapper<TextFieldElement> {
        let defaultValue = defaultBillingDetails(emailAPIPath: apiPath).email
        let element = TextFieldElement.makeEmail(defaultValue: defaultValue, theme: theme)
        return PaymentMethodElementWrapper(element) { textField, params in
            if let apiPath = apiPath {
                params.paymentMethodParams.additionalAPIParameters[apiPath] = textField.text
            } else {
                params.paymentMethodParams.nonnil_billingDetails.email = textField.text
            }
            return params
        }
    }

    func makePhone() -> PaymentMethodElementWrapper<PhoneNumberElement> {
        let element = PhoneNumberElement(
            defaultCountryCode: defaultBillingDetails().address.country,
            defaultPhoneNumber: defaultBillingDetails().phone,
            theme: theme)
        return PaymentMethodElementWrapper(element) { phoneField, params in
            guard case .valid = phoneField.validationState else { return nil }
            params.paymentMethodParams.nonnil_billingDetails.phone = phoneField.phoneNumber?.string(as: .e164)
            return params
        }
    }

    func makeMandate(mandateText: String) -> PaymentMethodElement {
        // If there was previous customer input, check if it displayed the mandate for this payment method
        let customerAlreadySawMandate = previousCustomerInput?.didDisplayMandate ?? false
        return SimpleMandateElement(mandateText: mandateText, customerAlreadySawMandate: customerAlreadySawMandate, theme: theme)
    }

    func makeBSB(apiPath: String? = nil) -> PaymentMethodElementWrapper<TextFieldElement> {
        let defaultValue = getPreviousCustomerInput(for: apiPath) ?? previousCustomerInput?.paymentMethodParams.auBECSDebit?.bsbNumber
        let element = TextFieldElement.Account.makeBSB(defaultValue: defaultValue, theme: theme)
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
        let defaultValue = getPreviousCustomerInput(for: apiPath) ?? previousCustomerInput?.paymentMethodParams.auBECSDebit?.accountNumber
        let element = TextFieldElement.Account.makeAUBECSAccountNumber(defaultValue: defaultValue, theme: theme)
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

    func makeSortCode() -> PaymentMethodElementWrapper<TextFieldElement> {
        let defaultValue = previousCustomerInput?.paymentMethodParams.bacsDebit?.sortCode
        let element = TextFieldElement.Account.makeSortCode(defaultValue: defaultValue, theme: theme)
        return PaymentMethodElementWrapper(element) { textField, params in
            let sortCodeText = BSBNumber(number: textField.text).bsbNumberText()
            params.paymentMethodParams.nonnil_bacsDebit.sortCode = sortCodeText
            return params
        }
    }

    func makeBacsAccountNumber() -> PaymentMethodElementWrapper<TextFieldElement> {
        let defaultValue = previousCustomerInput?.paymentMethodParams.bacsDebit?.accountNumber
        let element = TextFieldElement.Account.makeBacsAccountNumber(defaultValue: defaultValue, theme: theme)
        return PaymentMethodElementWrapper(element) { textField, params in
            params.paymentMethodParams.nonnil_bacsDebit.accountNumber = textField.text
            return params
        }
    }

    func makeBacsMandate() -> PaymentMethodElementWrapper<CheckboxElement> {
        let mandateText = String(format: String.Localized.bacs_mandate_text, configuration.merchantDisplayName)
        let element = CheckboxElement(
            theme: configuration.appearance.asElementsTheme,
            label: mandateText,
            isSelectedByDefault: false
        )
        return PaymentMethodElementWrapper(element) { checkbox, params in
            // Only return params if the mandate has been accepted
            return checkbox.isSelected ? params : nil
        }
    }

    func makeSepaMandate() -> PaymentMethodElement {
        let mandateText = String(format: String.Localized.sepa_mandate_text, configuration.merchantDisplayName)
        return makeMandate(mandateText: mandateText)
    }

    func makeCashAppMandate() -> PaymentMethodElement {
        let mandateText = String(format: String.Localized.cash_app_mandate_text, configuration.merchantDisplayName, configuration.merchantDisplayName)
        return makeMandate(mandateText: mandateText)
    }

    func makeRevolutPayMandate() -> PaymentMethodElement {
        let mandateText = String(format: String.Localized.revolut_pay_mandate_text, configuration.merchantDisplayName)
        return makeMandate(mandateText: mandateText)
    }

    func makePaypalMandate() -> PaymentMethodElement {
        let mandateText: String = {
            if isPaymentIntent {
                return String(format: String.Localized.paypal_mandate_text_payment, configuration.merchantDisplayName)
            } else {
                return String(format: String.Localized.paypal_mandate_text_setup, configuration.merchantDisplayName)
            }
        }()
        return makeMandate(mandateText: mandateText)
    }

    func makeSaveCheckbox(
        label: String = String.Localized.save_for_future_payments,
        didToggle: ((Bool) -> Void)? = nil
    ) -> PaymentMethodElementWrapper<CheckboxElement> {
        let isSelectedByDefault: Bool = {
            if let previousCustomerInput = previousCustomerInput, previousCustomerInput.saveForFutureUseCheckboxState != .hidden {
                // Use the previous customer input checkbox state if it was shown
                return previousCustomerInput.saveForFutureUseCheckboxState == .selected
            } else {
                // Otherwise, use the default selected state
                return configuration.savePaymentMethodOptInBehavior.isSelectedByDefault
            }
        }()
        let element = CheckboxElement(
            theme: configuration.appearance.asElementsTheme,
            label: label,
            isSelectedByDefault: isSelectedByDefault,
            didToggle: didToggle
        )
        return PaymentMethodElementWrapper(element) { checkbox, params in
            if checkbox.checkboxButton.isHidden {
                params.saveForFutureUseCheckboxState = .hidden
            } else {
                params.saveForFutureUseCheckboxState = checkbox.checkboxButton.isSelected ? .selected : .deselected
            }
            return params
        }
    }

    func makeBillingAddressSection(
        collectionMode: AddressSectionElement.CollectionMode = .all(),
        countries: [String]? = nil,
        countryAPIPath: String? = nil
    ) -> PaymentMethodElementWrapper<AddressSectionElement> {
        let displayBillingSameAsShippingCheckbox: Bool
        let defaultAddress: AddressSectionElement.AddressDetails
        if let shippingDetails = configuration.shippingDetails() {
            // If defaultBillingDetails and shippingDetails are both populated, prefer defaultBillingDetails
            displayBillingSameAsShippingCheckbox = defaultBillingDetails() == .init()
            defaultAddress =
                displayBillingSameAsShippingCheckbox
                ? .init(shippingDetails) : defaultBillingDetails().address.addressSectionDefaults
        } else {
            displayBillingSameAsShippingCheckbox = false
            defaultAddress = defaultBillingDetails().address.addressSectionDefaults
        }
        let section = AddressSectionElement(
            title: String.Localized.billing_address_lowercase,
            countries: countries,
            addressSpecProvider: addressSpecProvider,
            defaults: defaultAddress,
            collectionMode: collectionMode,
            additionalFields: .init(
                billingSameAsShippingCheckbox: displayBillingSameAsShippingCheckbox
                    ? .enabled(isOptional: false) : .disabled
            ),
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
            if let countryAPIPath {
                params.paymentMethodParams.additionalAPIParameters[countryAPIPath] = section.selectedCountryCode
            }

            return params
        }
    }

    // MARK: - PaymentMethod form definitions

    func makeSofort(spec: FormSpec) -> PaymentMethodElement {
        let contactSection: Element? = makeContactInformationSection(
            nameRequiredByPaymentMethod: saveMode == .merchantRequired,
            emailRequiredByPaymentMethod: saveMode == .merchantRequired,
            phoneRequiredByPaymentMethod: false
        )
        // Hack: Use the luxe spec to get the latest list of accepted countries rather than hardcoding it here
        let countries: [String]? = spec.fields.reduce(nil) { countries, fieldSpec in
            if case let .country(countrySpec) = fieldSpec {
                return countrySpec.allowedCountryCodes
            }
            return countries
        }

        let addressSection: Element? = {
            if configuration.billingDetailsCollectionConfiguration.address == .full {
                return makeBillingAddressSection(countries: countries, countryAPIPath: "sofort[country]")
            } else {
                return makeCountry(countryCodes: countries, apiPath: "sofort[country]")
            }
        }()
        let mandate: Element? = saveMode == .merchantRequired ? makeSepaMandate() : nil // Note: We show a SEPA mandate b/c sofort saves bank details as a SEPA Direct Debit Payment Method
        let elements: [Element?] = [contactSection, addressSection, mandate]
        return FormElement(
            autoSectioningElements: elements.compactMap { $0 },
            theme: theme
        )
    }

    func makeBancontact() -> PaymentMethodElement {
        let contactSection: Element? = makeContactInformationSection(
            nameRequiredByPaymentMethod: true,
            emailRequiredByPaymentMethod: saveMode == .merchantRequired,
            phoneRequiredByPaymentMethod: false
        )
        let addressSection: Element? = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)
        let mandate: Element? = saveMode == .merchantRequired ? makeSepaMandate() : nil // Note: We show a SEPA mandate b/c iDEAL saves bank details as a SEPA Direct Debit Payment Method
        let elements: [Element?] = [contactSection, addressSection, mandate]
        return FormElement(
            autoSectioningElements: elements.compactMap { $0 },
            theme: theme
        )
    }

    func makeBacsDebit() -> PaymentMethodElement {
        let contactSection: Element? = makeContactInformationSection(
            nameRequiredByPaymentMethod: true,
            emailRequiredByPaymentMethod: true,
            phoneRequiredByPaymentMethod: false
        )
        let addressSection: Element? = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: true)
        let sortCodeField = makeSortCode()
        let accountNumberField = makeBacsAccountNumber()
        let mandate = makeBacsMandate()
        let bacsAccountSection = SectionElement(
            title: String.Localized.bank_account_sentence_case,
            elements: [sortCodeField, accountNumberField],
            theme: theme
        )
        let elements: [Element?] = [contactSection, bacsAccountSection, addressSection, mandate]
        return FormElement(
            autoSectioningElements: elements.compactMap { $0 },
            theme: theme
        )
    }

    func makeiDEAL(spec: FormSpec) -> PaymentMethodElement {
        let contactSection: Element? = makeContactInformationSection(
            nameRequiredByPaymentMethod: true,
            emailRequiredByPaymentMethod: saveMode == .merchantRequired,
            phoneRequiredByPaymentMethod: false
        )
        // Hack: Use the luxe spec to make the dropdown for convenience; it has the latest list of banks
        let bankDropdown: Element? = spec.fields.reduce(nil) { dropdown, spec in
            // Find the dropdown spec
            if case .selector(let spec) = spec {
                return makeDropdown(for: spec)
            }
            return dropdown
        }

        let addressSection: Element? = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)
        let mandate: Element? = saveMode == .merchantRequired ? makeSepaMandate() : nil // Note: We show a SEPA mandate b/c iDEAL saves bank details as a SEPA Direct Debit Payment Method
        let elements: [Element?] = [contactSection, bankDropdown, addressSection, mandate]
        return FormElement(
            autoSectioningElements: elements.compactMap { $0 },
            theme: theme
        )
    }

    func makeUSBankAccount(merchantName: String) -> PaymentMethodElement {
        let isSaving = BoolReference()
        let saveCheckbox = makeSaveCheckbox(
            label: String(
                format: STPLocalizedString(
                    "Save this account for future %@ payments",
                    "Prompt next to checkbox to save bank account."
                ),
                merchantName
            )
        ) { value in
            isSaving.value = value
        }
        let shouldDisplaySaveCheckbox: Bool = saveMode == .userSelectable && !canSaveToLink
        isSaving.value =
            shouldDisplaySaveCheckbox
            ? configuration.savePaymentMethodOptInBehavior.isSelectedByDefault : saveMode == .merchantRequired

        let phoneElement = configuration.billingDetailsCollectionConfiguration.phone == .always ? makePhone() : nil
        let addressElement = configuration.billingDetailsCollectionConfiguration.address == .full
            ? makeBillingAddressSection(collectionMode: .all(), countries: nil)
            : nil
        connectBillingDetailsFields(
            countryElement: nil,
            addressElement: addressElement,
            phoneElement: phoneElement)

        return USBankAccountPaymentMethodElement(
            configuration: configuration,
            titleElement: makeUSBankAccountCopyLabel(),
            nameElement: configuration.billingDetailsCollectionConfiguration.name != .never ? makeName() : nil,
            emailElement: configuration.billingDetailsCollectionConfiguration.email != .never ? makeEmail() : nil,
            phoneElement: phoneElement,
            addressElement: addressElement,
            checkboxElement: shouldDisplaySaveCheckbox ? saveCheckbox : nil,
            savingAccount: isSaving,
            merchantName: merchantName,
            theme: theme
        )
    }

    func makeKonbini() -> PaymentMethodElement {
        let contactInfoSection = makeContactInformationSection(nameRequiredByPaymentMethod: true, emailRequiredByPaymentMethod: true, phoneRequiredByPaymentMethod: false)
        let billingDetails = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)
        let konbiniPhoneNumber = PaymentMethodElementWrapper(TextFieldElement.makeKonbini(theme: theme)) { textField, params in
            params.confirmPaymentMethodOptions.konbiniOptions = .init()
            params.confirmPaymentMethodOptions.konbiniOptions?.confirmationNumber = textField.text
            return params
        }
        let elements = [contactInfoSection, konbiniPhoneNumber, billingDetails].compactMap { $0 }
        return FormElement(autoSectioningElements: elements, theme: theme)
    }

    func makeExternalPayPal() -> PaymentMethodElement {
        let contactInfoSection = makeContactInformationSection(nameRequiredByPaymentMethod: false, emailRequiredByPaymentMethod: false, phoneRequiredByPaymentMethod: false)
        let billingDetails = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)
        return FormElement(elements: [contactInfoSection, billingDetails], theme: theme)
    }

    func makeSwish() -> PaymentMethodElement {
        let contactInfoSection = makeContactInformationSection(
            nameRequiredByPaymentMethod: false,
            emailRequiredByPaymentMethod: false,
            phoneRequiredByPaymentMethod: false
        )
        let billingDetails = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)
        return FormElement(elements: [contactInfoSection, billingDetails], theme: theme)
    }

    func makeCountry(countryCodes: [String]?, apiPath: String? = nil) -> PaymentMethodElement {
        let locale = Locale.current
        let resolvedCountryCodes = countryCodes ?? addressSpecProvider.countries
        let country = PaymentMethodElementWrapper(
            DropdownFieldElement.Address.makeCountry(
                label: String.Localized.country,
                countryCodes: resolvedCountryCodes,
                theme: theme,
                defaultCountry: defaultBillingDetails(countryAPIPath: apiPath).address.country,
                locale: locale
            )
        ) { dropdown, params in
            if let apiPath = apiPath {
                params.paymentMethodParams.additionalAPIParameters[apiPath] =
                    resolvedCountryCodes[dropdown.selectedIndex]
            } else {
                params.paymentMethodParams.nonnil_billingDetails.nonnil_address.country =
                    resolvedCountryCodes[dropdown.selectedIndex]
            }
            return params
        }
        return country
    }

    func makeIban(apiPath: String? = nil) -> PaymentMethodElementWrapper<TextFieldElement> {
        let defaultValue = getPreviousCustomerInput(for: apiPath) ?? previousCustomerInput?.paymentMethodParams.sepaDebit?.iban
        return PaymentMethodElementWrapper(TextFieldElement.makeIBAN(defaultValue: defaultValue, theme: theme)) { iban, params in
            if let apiPath = apiPath {
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
        guard let amount = amount, let currency = currency else {
            assertionFailure("After requires a non-nil amount and currency")
            return nil
        }

        return StaticElement(
            view: AfterpayPriceBreakdownView(
                amount: amount,
                currency: currency,
                theme: theme
            )
        )
    }

    func makeKlarnaCountry(apiPath: String? = nil) -> PaymentMethodElement? {
        guard let currency = currency else {
            assertionFailure("Klarna requires a non-nil currency")
            return nil
        }

        let countryCodes = Locale.current.sortedByTheirLocalizedNames(
            KlarnaHelper.availableCountries(currency: currency)
        )
        let defaultValue = getPreviousCustomerInput(for: apiPath) ?? defaultBillingDetails(countryAPIPath: apiPath).address.country
        let country = PaymentMethodElementWrapper(
            DropdownFieldElement.Address.makeCountry(
                label: String.Localized.country,
                countryCodes: countryCodes,
                theme: theme,
                defaultCountry: defaultValue,
                locale: Locale.current
            )
        ) { dropdown, params in
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
        let text =
            KlarnaHelper.canBuyNow()
            ? STPLocalizedString("Buy now or pay later with Klarna.", "Klarna buy now or pay later copy")
            : STPLocalizedString("Pay later with Klarna.", "Klarna pay later copy")
        return makeSectionTitleLabelWith(text: text)
    }

    private func makeUSBankAccountCopyLabel() -> StaticElement {
        switch configuration {
        case .customerSheet:
            return makeSectionTitleLabelWith(
                text: STPLocalizedString(
                    "Save your bank account in just a few steps.",
                    "US Bank Account copy title for Mobile payment element form"
                )
            )
        case .paymentSheet:
            return makeSectionTitleLabelWith(
                text: STPLocalizedString(
                    "Pay with your bank account in just a few steps.",
                    "US Bank Account copy title for Mobile payment element form"
                )
            )
        }
    }

    func makeSectionTitleLabelWith(text: String) -> StaticElement {
        let label = UILabel()
        label.text = text
        label.font = theme.fonts.subheadline
        label.textColor = theme.colors.secondaryText
        label.numberOfLines = 0
        return StaticElement(view: label)
    }

    /// This method returns a "Contact information" Section containing a name, email, and phone field depending on the `PaymentSheet.Configuration.billingDetailsCollectionConfiguration` and your payment method's required fields.
    /// - Parameter nameRequiredByPaymentMethod: Whether your payment method requires the name field.
    /// - Parameter emailRequiredByPaymentMethod: Whether your payment method requires the email field.
    /// - Parameter phoneRequiredByPaymentMethod: Whether your payment method requires the phone field.
    func makeContactInformationSection(nameRequiredByPaymentMethod: Bool, emailRequiredByPaymentMethod: Bool, phoneRequiredByPaymentMethod: Bool) -> SectionElement? {
        let config = configuration.billingDetailsCollectionConfiguration
        let nameElement = config.name == .always
            || (config.name == .automatic && nameRequiredByPaymentMethod) ? makeName() : nil
        let emailElement = config.email == .always
            || (config.email == .automatic && emailRequiredByPaymentMethod) ? makeEmail() : nil
        let phoneElement = config.phone == .always
            || (config.phone == .automatic && phoneRequiredByPaymentMethod) ? makePhone() : nil
        let elements = ([nameElement, emailElement, phoneElement] as [Element?]).compactMap { $0 }
        guard !elements.isEmpty else { return nil }

        return SectionElement(
            title: elements.count > 1 ? .Localized.contact_information : nil,
            elements: elements,
            theme: theme)
    }

    func makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: Bool) -> Element? {
        if configuration.billingDetailsCollectionConfiguration.address == .full
            || (configuration.billingDetailsCollectionConfiguration.address == .automatic && requiredByPaymentMethod) {
           return makeBillingAddressSection()
        } else {
            return nil
        }
    }

    func makeDefaultsApplierWrapper<T: PaymentMethodElement>(for element: T) -> PaymentMethodElementWrapper<T> {
        return PaymentMethodElementWrapper(
            element,
            defaultsApplier: { [configuration] _, params in
                // Only apply defaults when the flag is on.
                guard configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod else {
                    return params
                }

                if let name = configuration.defaultBillingDetails.name {
                    params.paymentMethodParams.nonnil_billingDetails.name = name
                }
                if let phone = configuration.defaultBillingDetails.phone {
                    params.paymentMethodParams.nonnil_billingDetails.phone = phone
                }
                if let email = configuration.defaultBillingDetails.email {
                    params.paymentMethodParams.nonnil_billingDetails.email = email
                }
                if configuration.defaultBillingDetails.address != .init() {
                    params.paymentMethodParams.nonnil_billingDetails.address =
                    STPPaymentMethodAddress(address: configuration.defaultBillingDetails.address)
                }
                return params
            },
            paramsUpdater: { element, params in
                return element.updateParams(params: params)
            })
    }

    func connectBillingDetailsFields(
        countryElement: PaymentMethodElementWrapper<DropdownFieldElement>?,
        addressElement: PaymentMethodElementWrapper<AddressSectionElement>?,
        phoneElement: PaymentMethodElementWrapper<PhoneNumberElement>?
    ) {
        // Using a closure because a function would require capturing self, which will be deallocated by the time
        // the closures below are called.
        let defaultBillingDetails = defaultBillingDetails()
        let updatePhone = { (phoneElement: PhoneNumberElement, countryCode: String) in
            // Only update the phone country if:
            // 1. It's different from the selected one,
            // 2. A default phone number was not provided.
            // 3. The phone field hasn't been modified yet.
            guard countryCode != phoneElement.selectedCountryCode
                    && defaultBillingDetails.phone == nil
                    && !phoneElement.hasBeenModified
            else {
                return
            }

            phoneElement.setSelectedCountryCode(countryCode, shouldUpdateDefaultNumber: true)
        }

        if let countryElement = countryElement {
            countryElement.element.didUpdate = { [updatePhone] _ in
                let countryCode = countryElement.element.selectedItem.rawData
                if let phoneElement = phoneElement {
                    updatePhone(phoneElement.element, countryCode)
                }
                if let addressElement = addressElement {
                    addressElement.element.selectedCountryCode = countryCode
                }
            }

            if let addressElement = addressElement,
               addressElement.element.selectedCountryCode != countryElement.element.selectedItem.rawData
            {
                addressElement.element.selectedCountryCode = countryElement.element.selectedItem.rawData
            }
        }

        if let addressElement = addressElement {
            addressElement.element.didUpdate = { [updatePhone] addressDetails in
                if let countryCode = addressDetails.address.country,
                   let phoneElement = phoneElement
                {
                    updatePhone(phoneElement.element, countryCode)
                }
            }
        }
    }
}

// MARK: - Extension helpers

extension FormElement {
    /// Conveniently nests single TextField, PhoneNumber, and DropdownFields in a Section
    convenience init(autoSectioningElements: [Element], theme: ElementsUITheme = .default) {
        let elements: [Element] = autoSectioningElements.map {
            if $0 is PaymentMethodElementWrapper<TextFieldElement>
                || $0 is PaymentMethodElementWrapper<DropdownFieldElement>
                || $0 is PaymentMethodElementWrapper<PhoneNumberElement>
            {
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
        return .init(
            address: .init(
                city: city,
                country: country,
                line1: line1,
                line2: line2,
                postalCode: postalCode,
                state: state
            )
        )
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

extension STPPaymentMethodAddress {
    /// Convenience initializer to create a `STPPaymentMethodAddress` from a `PaymentSheet.Address`
    convenience init(address: PaymentSheet.Address) {
        self.init()
        city = address.city
        country = address.country
        line1 = address.line1
        line2 = address.line2
        postalCode = address.postalCode
        state = address.state
    }
}
