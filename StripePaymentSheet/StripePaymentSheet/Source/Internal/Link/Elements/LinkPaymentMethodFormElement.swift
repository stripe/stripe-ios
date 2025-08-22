//
//  LinkPaymentMethodFormElement.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 9/30/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

fileprivate extension ConsumerPaymentDetails {
    var cardDetails: Details.Card? {
        switch details {
        case .card(let details):
            return details
        case .bankAccount:
            return nil
        case .unparsable:
            return nil
        }
    }
}

final class LinkPaymentMethodFormElement: Element {
    let collectsUserInput: Bool = true

    struct Params {
        let expiryDate: CardExpiryDate?
        let cvc: String?
        let billingDetails: STPPaymentMethodBillingDetails
        let setAsDefault: Bool
        let preferredNetwork: String?
    }

    var view: UIView {
        return formElement.view
    }

    weak var delegate: ElementDelegate?

    var validationState: ElementValidationState {
        return formElement.validationState
    }

    let paymentMethod: ConsumerPaymentDetails
    let isBillingDetailsUpdateFlow: Bool
    private let linkAppearance: LinkAppearance?

    let configuration: PaymentElementConfiguration

    private lazy var theme: ElementsAppearance = {
        var theme = LinkUI.appearance.asElementsTheme

        if let primaryColor = linkAppearance?.colors?.primary {
            theme.colors.primary = primaryColor
        }

        return theme
    }()

    var params: Params? {
        guard validationState.isValid else {
            return nil
        }

        let expiryDate = CardExpiryDate(expiryDateElement.text)
        if paymentMethod.type == .card && expiryDate == nil {
            return nil
        }

        // TODO(link): Replace `STPPaymentMethodBillingDetails` with a custom struct for Link.
        // This matches the object that was returned by CardDetailsEditView, but won't work
        // with `collectionMode: .all`, because extra fields won't match what expected by Link.
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = billingAddressSection?.name?.text ?? nameOnCardElement?.text
        billingDetails.nonnil_address.country = billingAddressSection?.selectedCountryCode
        billingDetails.nonnil_address.line1 = billingAddressSection?.line1?.text
        billingDetails.nonnil_address.line2 = billingAddressSection?.line2?.text
        billingDetails.nonnil_address.city = billingAddressSection?.city?.text
        billingDetails.nonnil_address.state = billingAddressSection?.state?.rawData
        billingDetails.nonnil_address.postalCode = billingAddressSection?.postalCode?.text

        if let phone = billingAddressSection?.phone?.phoneNumber?.string(as: .e164) {
            billingDetails.phone = phone
        }
        if let email = billingAddressSection?.email?.text {
            billingDetails.email = email
        }

        let preferredNetwork = cardBrandDropdownElement?.element.selectedItem.rawData

        return Params(
            expiryDate: expiryDate,
            cvc: isBillingDetailsUpdateFlow ? nil : cvcElement.text,
            billingDetails: billingDetails,
            setAsDefault: checkboxElement.checkboxButton.isSelected,
            preferredNetwork: preferredNetwork
        )
    }

    private var showNameFieldInBillingAddressSection: Bool {
        // If we're showing this form for payment methods other than cards, we can't rely on the cardholder name field
        // in the card section. Therefore, we show it in the address section.
        let isCard = paymentMethod.type == .card
        let collectsName = configuration.billingDetailsCollectionConfiguration.name == .always
        return !isCard && collectsName
    }

    private lazy var nameOnCardElement: TextFieldElement? = {
        guard configuration.billingDetailsCollectionConfiguration.name == .always else { return nil }

        return TextFieldElement.makeName(
            label: STPLocalizedString("Name on card", "Label for name on card field"),
            defaultValue: paymentMethod.billingAddress?.name ?? configuration.defaultBillingDetails.name,
            theme: theme
        )
    }()

    private lazy var cardBrandDropdownElement: PaymentMethodElementWrapper<DropdownFieldElement>? = {
        guard let cardBrands = paymentMethod.cardDetails?.availableNetworks, cardBrands.count > 1 else {
            return nil
        }

        let cardBrandDropdown = DropdownFieldElement.makeCardBrandDropdown(
            cardBrands: Set(cardBrands),
            disallowedCardBrands: [
                // We will add brands from card brand filtering here
            ],
            theme: theme,
            includePlaceholder: false
        )

        if let selectedBrand = paymentMethod.cardDetails?.cardBrand {
            let index = cardBrandDropdown.items.firstIndex { item in
                item.rawData == STPCardBrandUtilities.apiValue(from: selectedBrand)
            }

            if let index {
                cardBrandDropdown.selectedIndex = Int(index)
            }
        }

        return PaymentMethodElementWrapper<DropdownFieldElement>(cardBrandDropdown) { field, params in
            let cardBrand = cardBrands[field.selectedIndex]
            let preferredNetworkAPIValue = STPCardBrandUtilities.apiValue(from: cardBrand)
            params.paymentMethodParams.card?.networks = .init(preferred: preferredNetworkAPIValue)
            return params
        }
    }()

    private lazy var panElement: TextFieldElement = {
        let isCoBranded = cardBrandDropdownElement != nil

        let panElementConfig = TextFieldElement.LastFourConfiguration(
            lastFour: paymentMethod.cardDetails?.last4 ?? "",
            editConfiguration: isCoBranded ? .readOnlyWithoutDisabledAppearance : .readOnly,
            cardBrand: paymentMethod.cardDetails?.cardBrand,
            cardBrandDropDown: cardBrandDropdownElement?.element
        )

        return panElementConfig.makeElement(theme: LinkUI.appearance.asElementsTheme)
    }()

    private lazy var cvcElement: TextFieldElement = {
        let configuration: TextFieldElementConfiguration = if isBillingDetailsUpdateFlow {
            TextFieldElement.CensoredCVCConfiguration(
                brand: paymentMethod.cardDetails?.stpBrand ?? .unknown
            )
        } else {
            TextFieldElement.CVCConfiguration(
                cardBrandProvider: { [weak self] in
                    self?.paymentMethod.cardDetails?.stpBrand ?? .unknown
                }
            )
        }

        return TextFieldElement(configuration: configuration, theme: theme)
    }()

    private lazy var expiryDateElement = TextFieldElement(
        configuration: TextFieldElement.ExpiryDateConfiguration(),
        theme: theme
    )

    private lazy var checkboxElement = CheckboxElement(
        theme: theme,
        label: String.Localized.set_as_default_payment_method,
        isSelectedByDefault: paymentMethod.isDefault
    )

    private lazy var formElement: FormElement = {
        var elements: [Element?] = []

        if paymentMethod.type == .card {
            elements.append(cardSection)
        }

        elements.append(billingAddressSection)
        elements.append(checkboxElement)

        let formElement = FormElement(
            elements: elements,
            theme: theme,
            customSpacing: [(cardSection, LinkUI.largeContentSpacing)]
        )
        formElement.toggleChild(cardSection, show: paymentMethod.type == .card, animated: false)
        formElement.delegate = self
        return formElement
    }()

    private lazy var cardSection: SectionElement = {
        let allElements: [Element?] = [
            nameOnCardElement,
            panElement, SectionElement.HiddenElement(cardBrandDropdownElement),
            SectionElement.MultiElementRow([expiryDateElement, cvcElement], theme: theme),
        ]
        let elements = allElements.compactMap { $0 }

        return SectionElement(
            title: String.Localized.card_information,
            elements: elements,
            theme: theme
        )
    }()

    private lazy var billingAddressSection: AddressSectionElement? = {
        let collectPhone = configuration.billingDetailsCollectionConfiguration.phone == .always && isBillingDetailsUpdateFlow
        let collectEmail = configuration.billingDetailsCollectionConfiguration.email == .always
        let collectAddress = configuration.billingDetailsCollectionConfiguration.address != .never || paymentMethod.type == .card

        guard collectPhone || collectEmail || collectAddress else {
            return nil
        }

        let phone: String? = if collectPhone {
            configuration.defaultBillingDetails.phone
        } else {
            nil
        }

        let email: String? = if collectEmail {
            paymentMethod.billingEmailAddress ?? configuration.defaultBillingDetails.email
        } else {
            nil
        }

        let name = paymentMethod.billingAddress?.name ?? configuration.defaultBillingDetails.name

        let defaultBillingAddress = AddressSectionElement.AddressDetails(
            billingAddress: paymentMethod.billingAddress ?? .init(),
            phone: phone,
            name: name,
            email: email
        )

        let additionalFields = AddressSectionElement.AdditionalFields(
            name: showNameFieldInBillingAddressSection ? .enabled(isOptional: false) : .disabled,
            phone: collectPhone ? .enabled(isOptional: false) : .disabled,
            email: collectEmail ? .enabled(isOptional: false) : .disabled
        )

        return AddressSectionElement(
            title: String.Localized.billing_address_lowercase,
            countries: isBillingDetailsUpdateFlow ? configuration.billingDetailsCollectionConfiguration.allowedCountriesArray : nil,
            defaults: defaultBillingAddress,
            collectionMode: configuration.billingDetailsCollectionConfiguration.address == .full
                ? .all()
                : .countryAndPostal(),
            additionalFields: additionalFields,
            theme: theme
        )
    }()

    init(paymentMethod: ConsumerPaymentDetails, configuration: PaymentElementConfiguration, isBillingDetailsUpdateFlow: Bool, linkAppearance: LinkAppearance? = nil) {
        self.paymentMethod = paymentMethod
        self.configuration = configuration
        self.isBillingDetailsUpdateFlow = isBillingDetailsUpdateFlow
        self.linkAppearance = linkAppearance

        if let expiryDate = paymentMethod.cardDetails?.expiryDate {
            self.expiryDateElement.setText(expiryDate.displayString)
        }

//        self.checkboxElement.checkboxButton.isHidden = paymentMethod.isDefault
        // This checkbox is confusing, so we'll always hide it for now. We'll bring it back once we work out the design.
        self.checkboxElement.checkboxButton.isHidden = true
    }

    func showAllValidationErrors() {
        formElement.showAllValidationErrors()
    }
}

extension LinkPaymentMethodFormElement: ElementDelegate {

    func didUpdate(element: Element) {
        delegate?.didUpdate(element: self)
    }

    func continueToNextField(element: Element) {
        delegate?.continueToNextField(element: self)
    }

}

private extension ConsumerPaymentDetails.Details.Card {

    var cardBrand: STPCardBrand {
        STPCard.brand(from: brand)
    }

    var availableNetworks: [STPCardBrand] {
        networks.map { STPCard.brand(from: $0) }.filter { $0 != .unknown }
    }
}
