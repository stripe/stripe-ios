//
//  CardFormElement.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 3/22/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCore

extension PaymentSheetFormFactory {
    func makeCard() -> PaymentMethodElement {
        let isLinkEnabled = offerSaveToLinkWhenSupported && canSaveToLink
        let saveCheckbox = makeSaveCheckbox(
            label: String.Localized.save_this_card_for_future_$merchant_payments(
                merchantDisplayName: configuration.merchantDisplayName
            )
        )
        let shouldDisplaySaveCheckbox: Bool = saveMode == .userSelectable && !canSaveToLink
        let cardFormElement = FormElement(elements: [
            CardSection(),
            makeBillingAddressSection(collectionMode: .countryAndPostal(countriesRequiringPostalCollection: ["US", "GB", "CA"])),
            shouldDisplaySaveCheckbox ? saveCheckbox : nil
        ])
        if isLinkEnabled {
            return LinkEnabledPaymentMethodElement(
                type: .card,
                paymentMethodElement: cardFormElement,
                configuration: configuration,
                linkAccount: linkAccount
            )
        } else {
            return cardFormElement
        }
    }
}
