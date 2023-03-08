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
    func makeCard(theme: ElementsUITheme = .default) -> PaymentMethodElement {
        let isLinkEnabled = offerSaveToLinkWhenSupported && canSaveToLink
        let saveCheckbox = makeSaveCheckbox(
            label: String.Localized.save_this_card_for_future_$merchant_payments(
                merchantDisplayName: configuration.merchantDisplayName
            )
        )
        let shouldDisplaySaveCheckbox: Bool = saveMode == .userSelectable && !canSaveToLink

        // Link can't collect phone.
        let includePhone = !configuration.linkPaymentMethodsOnly
            && configuration.billingDetailsCollectionConfiguration.phone == .always

        let contactInformationSection = makeContactInformation(
            includeName: false, // Name is included in the card details section.
            includeEmail: configuration.billingDetailsCollectionConfiguration.email == .always,
            includePhone: includePhone)

        let cardSection = CardSection(
            collectName: configuration.billingDetailsCollectionConfiguration.name == .always,
            defaultName: configuration.defaultBillingDetails.name,
            theme: theme)

        let billingAddressSection: PaymentMethodElement? = {
            switch configuration.billingDetailsCollectionConfiguration.address {
            case .automatic:
                return makeBillingAddressSection(collectionMode: .countryAndPostal(), countries: nil)
            case .full:
                return makeBillingAddressSection(collectionMode: .all(), countries: nil)
            case .never:
                return nil
            }
        }()

        let cardFormElement = FormElement(
            elements: [
                contactInformationSection,
                cardSection,
                billingAddressSection,
                shouldDisplaySaveCheckbox ? saveCheckbox : nil,
            ],
            theme: theme)

        let cardFormElementWrapper = PaymentMethodElementWrapper(
            cardFormElement,
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

        if isLinkEnabled {
            return LinkEnabledPaymentMethodElement(
                type: .card,
                paymentMethodElement: cardFormElementWrapper,
                configuration: configuration,
                linkAccount: linkAccount,
                country: intent.countryCode
            )
        } else {
            return cardFormElementWrapper
        }
    }
}
