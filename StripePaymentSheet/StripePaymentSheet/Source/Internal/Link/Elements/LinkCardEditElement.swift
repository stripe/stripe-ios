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

// TODO(ramont): Remove after migrating to modern bindings
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
    struct Params {
        let expiryDate: CardExpiryDate
        let cvc: String
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

    let configuration: PaymentSheet.Configuration

    let theme: ElementsUITheme = LinkUI.appearance.asElementsTheme

    var params: Params? {
        guard validationState.isValid,
              let expiryDate = CardExpiryDate(expiryDateElement.text) else {
            return nil
        }

        // TODO(ramont): Replace `STPPaymentMethodBillingDetails` with a custom struct for Link.
        // This matches the object that was returned by CardDetailsEditView, but won't work
        // with `collectionMode: .all`, because extra fields won't match what expected by Link.
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = nameElement?.text
        billingDetails.email = emailElement?.text
        billingDetails.nonnil_address.country = billingAddressSection?.selectedCountryCode
        billingDetails.nonnil_address.line1 = billingAddressSection?.line1?.text
        billingDetails.nonnil_address.line2 = billingAddressSection?.line2?.text
        billingDetails.nonnil_address.city = billingAddressSection?.city?.text
        billingDetails.nonnil_address.state = billingAddressSection?.state?.rawData
        billingDetails.nonnil_address.postalCode = billingAddressSection?.postalCode?.text

        return Params(
            expiryDate: expiryDate,
            cvc: cvcElement.text,
            billingDetails: billingDetails,
            setAsDefault: checkboxElement.checkboxButton.isSelected
        )
    }

    private lazy var emailElement: TextFieldElement? = {
        guard configuration.billingDetailsCollectionConfiguration.email == .always else { return nil }

        return TextFieldElement.makeEmail(defaultValue: nil, theme: theme)
    }()

    private lazy var contactInformationSection: SectionElement? = {
        guard let emailElement = emailElement else { return nil }

        return SectionElement(
            title: STPLocalizedString("Contact information", "Title for the contact information section"),
            elements: [emailElement],
            theme: theme)
    }()

    private lazy var nameElement: TextFieldElement? = {
        guard configuration.billingDetailsCollectionConfiguration.name == .always else { return nil }

        return TextFieldElement.makeName(
            label: STPLocalizedString("Name on card", "Label for name on card field"),
            defaultValue: nil,
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

    private lazy var cvcElement = TextFieldElement(
        configuration: TextFieldElement.CVCConfiguration(
            cardBrandProvider: { [weak self] in
                self?.paymentMethod.cardDetails?.stpBrand ?? .unknown
            }
        ),
        theme: theme
    )

    private lazy var expiryDateElement = TextFieldElement(
        configuration: TextFieldElement.ExpiryDateConfiguration(),
        theme: theme
    )

    private lazy var checkboxElement = CheckboxElement(
        theme: theme,
        label: STPLocalizedString(
            "Set as default payment method",
            "Label of a checkbox that when checked makes a payment method as the default one."
        ),
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
            theme: theme
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

        return AddressSectionElement(
            title: String.Localized.billing_address,
            collectionMode: configuration.billingDetailsCollectionConfiguration.address == .full
                ? .all()
                : .countryAndPostal(),
            theme: theme
        )
    }()

    init(paymentMethod: ConsumerPaymentDetails, configuration: PaymentSheet.Configuration) {
        self.paymentMethod = paymentMethod
        self.configuration = configuration

        if let expiryDate = paymentMethod.cardDetails?.expiryDate {
            self.expiryDateElement.setText(expiryDate.displayString)
        }

        self.checkboxElement.checkboxButton.isHidden = paymentMethod.isDefault
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

        func accessoryView(for text: String, theme: ElementsUITheme) -> UIView? {
            paymentMethod.cardDetails.map { cardDetails in
                let image = STPImageLibrary.cardBrandImage(for: cardDetails.stpBrand)
                return UIImageView(image: image)
            }
        }
    }

}
