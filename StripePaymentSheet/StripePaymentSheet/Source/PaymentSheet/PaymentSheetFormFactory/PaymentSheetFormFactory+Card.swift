//
//  PaymentSheetFormFactory+Card.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 3/22/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import StripePayments
@_spi(STP) import StripeUICore
import UIKit

extension PaymentSheetFormFactory {
    func makeCard(cardBrandChoiceEligible: Bool = false) -> PaymentMethodElement {
        let showLinkInlineSignup = showLinkInlineCardSignup
        let defaultCheckbox: Element? = {
            guard allowsSetAsDefaultPM else {
                return nil
            }
            let defaultCheckbox = makeDefaultCheckbox()
            return shouldDisplayDefaultCheckbox ? defaultCheckbox : SectionElement.HiddenElement(defaultCheckbox)
        }()
        let saveCheckbox = makeSaveCheckbox(
            label: String.Localized.save_payment_details_for_future_$merchant_payments(
                merchantDisplayName: configuration.merchantDisplayName
            )
        ) { selected in
            defaultCheckbox?.view.isHidden = !selected
        }
        defaultCheckbox?.view.isHidden = !saveCheckbox.element.isSelected

        // Make section titled "Contact Information" w/ phone and email if merchant requires it.
        let optionalPhoneAndEmailInformationSection: SectionElement? = {
            let emailElement: Element? = configuration.billingDetailsCollectionConfiguration.email == .always ? makeEmail() : nil
            let shouldIncludePhone = configuration.billingDetailsCollectionConfiguration.phone == .always
            let phoneElement: Element? = shouldIncludePhone ? makePhone() : nil
            let contactInformationElements = [emailElement, phoneElement].compactMap { $0 }
            guard !contactInformationElements.isEmpty else {
                return nil
            }
            return SectionElement(
                title: .Localized.contact_information,
                elements: contactInformationElements,
                theme: theme
            )
        }()

        let previousCardInput = previousCustomerInput?.paymentMethodParams.card
        let formattedExpiry: String? = {
            guard let expiryMonth = previousCardInput?.expMonth?.intValue, let expiryYear = previousCardInput?.expYear?.intValue else {
                return nil
            }
            return String(format: "%02d%02d", expiryMonth, expiryYear % 100) // Modulo 100 as safeguard to get last 2 digits of the expiry
        }()
        let cardDefaultValues = CardSectionElement.DefaultValues(
            name: defaultBillingDetails().name,
            pan: previousCardInput?.number,
            cvc: previousCardInput?.cvc,
            expiry: formattedExpiry
        )

        let cardSection = CardSectionElement(
            collectName: configuration.billingDetailsCollectionConfiguration.name == .always,
            defaultValues: cardDefaultValues,
            preferredNetworks: configuration.preferredNetworks,
            cardBrandChoiceEligible: cardBrandChoiceEligible,
            hostedSurface: .init(config: configuration),
            theme: theme,
            analyticsHelper: analyticsHelper,
            cardBrandFilter: configuration.cardBrandFilter
        )

        let billingAddressSection: PaymentMethodElementWrapper<AddressSectionElement>? = {
            switch configuration.billingDetailsCollectionConfiguration.address {
            case .automatic:
                return makeBillingAddressSection(collectionMode: .countryAndPostal(), countries: nil)
            case .full:
                return makeBillingAddressSection(collectionMode: .all(), countries: nil)
            case .never:
                return nil
            }
        }()

        let phoneElement = optionalPhoneAndEmailInformationSection?.elements.compactMap {
            $0 as? PaymentMethodElementWrapper<PhoneNumberElement>
        }.first

        connectBillingDetailsFields(
            countryElement: nil,
            addressElement: billingAddressSection,
            phoneElement: phoneElement)

        var elements: [Element?] = [
            optionalPhoneAndEmailInformationSection,
            cardSection,
            billingAddressSection,
            shouldDisplaySaveCheckbox ? saveCheckbox : nil,
            defaultCheckbox,
        ]

        if case .paymentElement(let configuration) = configuration, let accountService, showLinkInlineSignup {
            let inlineSignupElement = LinkInlineSignupElement(
                configuration: configuration,
                linkAccount: linkAccount,
                country: countryCode,
                showCheckbox: !shouldDisplaySaveCheckbox,
                accountService: accountService
            )
            elements.append(inlineSignupElement)
        }

        let mandate: SimpleMandateElement? = {
            if isSettingUp {
                return makeMandate(mandateText: String(format: .Localized.by_providing_your_card_information_text, configuration.merchantDisplayName))

            }
            return nil
        }()
        elements.append(mandate)

        var customSpacing: [(Element, CGFloat)] = []
        if configuration.linkPaymentMethodsOnly {
            customSpacing.append((cardSection, LinkUI.largeContentSpacing))
        }

        return FormElement(
            elements: elements,
            theme: theme,
            customSpacing: customSpacing)
    }
}
