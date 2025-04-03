//
//  LinkCardEditElement.swift
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

final class LinkCardEditElement: Element {
    let collectsUserInput: Bool = true

    struct Params {
        let expiryDate: CardExpiryDate
        let cvc: String?
        let billingDetails: STPPaymentMethodBillingDetails
        let setAsDefault: Bool
    }

    var view: UIView {
        return formElement.view
    }

    weak var delegate: ElementDelegate?

    var validationState: ElementValidationState {
        return formElement.validationState
    }

    let paymentMethod: ConsumerPaymentDetails
    let useCVCPlaceholder: Bool

    let configuration: PaymentElementConfiguration

    let theme: ElementsAppearance = LinkUI.appearance.asElementsTheme

    var params: Params? {
        guard validationState.isValid,
              let expiryDate = CardExpiryDate(expiryDateElement.text) else {
            return nil
        }

        // TODO(link): Replace `STPPaymentMethodBillingDetails` with a custom struct for Link.
        // This matches the object that was returned by CardDetailsEditView, but won't work
        // with `collectionMode: .all`, because extra fields won't match what expected by Link.
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = nameElement?.text
        billingDetails.email = emailElement?.text
        billingDetails.phone = phoneElement?.phoneNumber?.string(as: .e164)
        billingDetails.nonnil_address.country = billingAddressSection?.selectedCountryCode
        billingDetails.nonnil_address.line1 = billingAddressSection?.line1?.text
        billingDetails.nonnil_address.line2 = billingAddressSection?.line2?.text
        billingDetails.nonnil_address.city = billingAddressSection?.city?.text
        billingDetails.nonnil_address.state = billingAddressSection?.state?.rawData
        billingDetails.nonnil_address.postalCode = billingAddressSection?.postalCode?.text

        return Params(
            expiryDate: expiryDate,
            cvc: useCVCPlaceholder ? nil : cvcElement.text,
            billingDetails: billingDetails,
            setAsDefault: checkboxElement.checkboxButton.isSelected
        )
    }

    private lazy var emailElement: TextFieldElement? = {
        guard configuration.billingDetailsCollectionConfiguration.email == .always else { return nil }

        return TextFieldElement.makeEmail(defaultValue: configuration.defaultBillingDetails.email, theme: theme)
    }()

    private lazy var phoneElement: PhoneNumberElement? = {
        guard configuration.billingDetailsCollectionConfiguration.phone == .always else { return nil }
        return PhoneNumberElement(
            defaultCountryCode: configuration.defaultBillingDetails.address.country,
            defaultPhoneNumber: configuration.defaultBillingDetails.phone,
            theme: theme
        )
    }()

    private lazy var contactInformationSection: SectionElement? = {
        let elements = ([emailElement, phoneElement] as [Element?]).compactMap { $0 }

        guard elements.isEmpty == false else { return nil }

        return SectionElement(
            title: elements.count > 1 ? .Localized.contact_information : nil,
            elements: elements,
            theme: theme
        )
    }()

    private lazy var nameElement: TextFieldElement? = {
        guard configuration.billingDetailsCollectionConfiguration.name == .always else { return nil }

        return TextFieldElement.makeName(
            label: STPLocalizedString("Name on card", "Label for name on card field"),
            defaultValue: paymentMethod.billingAddress?.name,
            theme: theme)
    }()

    private lazy var panElement: TextFieldElement = {
        let panElement = TextFieldElement(
            configuration: PANConfiguration(paymentMethod: paymentMethod),
            theme: theme
        )
        panElement.view.isUserInteractionEnabled = false
        return panElement
    }()

    private lazy var cvcElement: TextFieldElement = {
        let configuration: TextFieldElementConfiguration = if useCVCPlaceholder {
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
        let formElement = FormElement(
            elements: [
                contactInformationSection,
                cardSection,
                billingAddressSection,
                checkboxElement,
            ],
            theme: theme,
            customSpacing: [(cardSection, LinkUI.largeContentSpacing)]
        )
        formElement.delegate = self
        return formElement
    }()

    private lazy var cardSection: SectionElement = {
        let allElements: [Element?] = [
            nameElement,
            panElement,
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
        guard configuration.billingDetailsCollectionConfiguration.address != .never else { return nil }

        let defaultBillingAddress = AddressSectionElement.AddressDetails(billingAddress: paymentMethod.billingAddress ?? .init(), phone: nil)
        return AddressSectionElement(
            title: String.Localized.billing_address_lowercase,
            defaults: defaultBillingAddress,
            collectionMode: configuration.billingDetailsCollectionConfiguration.address == .full
                ? .all()
                : .countryAndPostal(),
            theme: theme
        )
    }()

    init(paymentMethod: ConsumerPaymentDetails, configuration: PaymentElementConfiguration, useCVCPlaceholder: Bool) {
        self.paymentMethod = paymentMethod
        self.configuration = configuration
        self.useCVCPlaceholder = useCVCPlaceholder

        if let expiryDate = paymentMethod.cardDetails?.expiryDate {
            self.expiryDateElement.setText(expiryDate.displayString)
        }

//        self.checkboxElement.checkboxButton.isHidden = paymentMethod.isDefault
        // This checkbox is confusing, so we'll always hide it for now. We'll bring it back once we work out the design.
        self.checkboxElement.checkboxButton.isHidden = true
    }

}

extension LinkCardEditElement: ElementDelegate {

    func didUpdate(element: Element) {
        delegate?.didUpdate(element: self)
    }

    func continueToNextField(element: Element) {
        delegate?.continueToNextField(element: self)
    }

}

private extension LinkCardEditElement {

    struct PANConfiguration: TextFieldElementConfiguration {
        let paymentMethod: ConsumerPaymentDetails

        var label: String {
            String.Localized.card_number
        }

        var defaultValue: String? {
            paymentMethod.cardDetails.map { "•••• \($0.last4)" }
        }

        func accessoryView(for text: String, theme: ElementsAppearance) -> UIView? {
            paymentMethod.cardDetails.map { cardDetails in
                let image = STPImageLibrary.cardBrandImage(for: cardDetails.stpBrand)
                return UIImageView(image: image)
            }
        }
    }

}
