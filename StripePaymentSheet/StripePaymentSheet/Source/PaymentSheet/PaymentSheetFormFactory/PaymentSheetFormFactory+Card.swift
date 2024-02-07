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
        let isLinkEnabled = offerSaveToLinkWhenSupported && canSaveToLink
        let saveCheckbox = makeSaveCheckbox(
            label: String.Localized.save_this_card_for_future_$merchant_payments(
                merchantDisplayName: configuration.merchantDisplayName
            )
        )
        let shouldDisplaySPMSaveCheckbox: Bool = saveMode == .userSelectable && (configuration.allowLinkV2Features || !canSaveToLink)

        // Make section titled "Contact Information" w/ phone and email if merchant requires it.
        let optionalPhoneAndEmailInformationSection: SectionElement? = {
            let emailElement: Element? = configuration.billingDetailsCollectionConfiguration.email == .always ? makeEmail() : nil
            // Link can't collect phone.
            let shouldIncludePhone = !configuration.linkPaymentMethodsOnly && configuration.billingDetailsCollectionConfiguration.phone == .always
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
            return String(format: "%02d%02d", expiryMonth, expiryYear)
        }()
        let cardDefaultValues = CardSection.DefaultValues(
            name: defaultBillingDetails().name,
            pan: previousCardInput?.number,
            cvc: previousCardInput?.cvc,
            expiry: formattedExpiry
        )

        let cardSection = CardSection(
            collectName: configuration.billingDetailsCollectionConfiguration.name == .always,
            defaultValues: cardDefaultValues,
            preferredNetworks: configuration.preferredNetworks,
            cardBrandChoiceEligible: cardBrandChoiceEligible,
            hostedSurface: .init(config: configuration),
            theme: theme
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

        let cardFormElement = FormElement(
            elements: [
                optionalPhoneAndEmailInformationSection,
                cardSection,
                billingAddressSection,
                shouldDisplaySPMSaveCheckbox ? saveCheckbox : nil,
            ],
            theme: theme)

        if case .paymentSheet(let configuration) = configuration, isLinkEnabled {
            return LinkEnabledPaymentMethodElement(
                type: .card,
                paymentMethodElement: cardFormElement,
                configuration: configuration,
                linkAccount: linkAccount,
                country: countryCode,
                showCheckbox: !(shouldDisplaySPMSaveCheckbox && configuration.allowLinkV2Features)
            )
        } else {
            return cardFormElement
        }
    }
    func makeCardCVCCollection(paymentMethod: STPPaymentMethod,
                               mode: CVCRecollectionElement.Mode,
                               appearance: PaymentSheet.Appearance) -> CVCRecollectionElement {
        return CVCRecollectionElement(paymentMethod: paymentMethod, mode: mode, appearance: appearance)
    }
}
