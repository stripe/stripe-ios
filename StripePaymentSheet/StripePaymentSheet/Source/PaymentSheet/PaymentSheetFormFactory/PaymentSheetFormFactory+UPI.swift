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

    func makeUPI() -> FormElement {
        let contactInformationElement = makeContactInformationSection(nameRequiredByPaymentMethod: false, emailRequiredByPaymentMethod: false, phoneRequiredByPaymentMethod: false)
        let billingAddressElement = configuration.billingDetailsCollectionConfiguration.address == .full
            ? makeBillingAddressSection(countries: nil)
            : nil
        let phoneElement = contactInformationElement?.elements.compactMap {
            $0 as? PaymentMethodElementWrapper<PhoneNumberElement>
        }.first
        connectBillingDetailsFields(
            countryElement: nil,
            addressElement: billingAddressElement,
            phoneElement: phoneElement)

        let allElements: [Element?] = [
            makeUPIHeader(),
            makeVPAField(),
            contactInformationElement,
            billingAddressElement,
        ]
        let autoSectioningElements = allElements.compactMap { $0 }
        return FormElement(autoSectioningElements: autoSectioningElements, theme: theme)
    }

    private func makeUPIHeader() -> SubtitleElement {
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
