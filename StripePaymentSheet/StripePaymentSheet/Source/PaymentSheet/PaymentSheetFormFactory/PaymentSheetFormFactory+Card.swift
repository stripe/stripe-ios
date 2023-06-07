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
    func makeCard() -> PaymentMethodElement {
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

        let phoneElement = contactInformationSection?.elements.compactMap {
            $0 as? PaymentMethodElementWrapper<PhoneNumberElement>
        }.first

        connectBillingDetailsFields(
            countryElement: nil,
            addressElement: billingAddressSection,
            phoneElement: phoneElement)

        let cardFormElement = FormElement(
            elements: [
                contactInformationSection,
                cardSection,
                billingAddressSection,
                shouldDisplaySaveCheckbox ? saveCheckbox : nil,
            ],
            theme: theme)
        let cardFormElementWrapper = makeDefaultsApplierWrapper(for: cardFormElement)

        if case .paymentSheet(let configuration) = configuration, isLinkEnabled {
            return LinkEnabledPaymentMethodElement(
                type: .card,
                paymentMethodElement: cardFormElementWrapper,
                configuration: configuration,
                linkAccount: linkAccount,
                country: countryCode
            )
        } else {
            return cardFormElementWrapper
        }
    }
}
