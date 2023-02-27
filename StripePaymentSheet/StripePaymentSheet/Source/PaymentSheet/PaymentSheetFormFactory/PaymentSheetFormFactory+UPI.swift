//
//  PaymentSheetFormFactory+UPI.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 9/6/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

extension PaymentSheetFormFactory {

    func makeUPI() -> PaymentMethodElement {
        let contactInformationElement = makeContactInformation(
            includeName: configuration.billingDetailsCollectionConfiguration.name == .always,
            includeEmail: configuration.billingDetailsCollectionConfiguration.email == .always,
            includePhone: configuration.billingDetailsCollectionConfiguration.phone == .always)
        let billingAddressElement = configuration.billingDetailsCollectionConfiguration.address == .full
            ? makeBillingAddressSection(countries: nil)  // Should we restrict to India?
            : nil

        let allElements: [Element?] = [
            makeUPIHeader(),
            makeVPAField(),
            contactInformationElement,
            billingAddressElement,
        ]
        let autoSectioningElements = allElements.compactMap { $0 }
        let formElement = FormElement(autoSectioningElements: autoSectioningElements, theme: theme)
        return PaymentMethodElementWrapper(
            formElement,
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

    private func makeUPIHeader() -> StaticElement {
        return makeSectionTitleLabelWith(text: STPLocalizedString("Buy using a UPI ID",
                                                                  "Header text shown above a UPI ID text field"))
    }

    private func makeVPAField() -> PaymentMethodElementWrapper<TextFieldElement> {
        return PaymentMethodElementWrapper(TextFieldElement.makeVPA(theme: theme)) { vpa, params in
            let upi = params.paymentMethodParams.upi ?? STPPaymentMethodUPIParams()
            upi.vpa = vpa.text
            params.paymentMethodParams.upi = upi
            return params
        }
    }
}
