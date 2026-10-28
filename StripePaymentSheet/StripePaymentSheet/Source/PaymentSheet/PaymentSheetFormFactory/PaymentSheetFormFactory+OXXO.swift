//
//  File.swift
//  StripePaymentSheet
//
//  Created by Eduardo Urias on 9/6/23.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

extension PaymentSheetFormFactory {

    func makeOXXO() -> FormElement {
        let contactInformationElement = makeContactInformationSection(
            nameRequiredByPaymentMethod: true,
            emailRequiredByPaymentMethod: true,
            phoneRequiredByPaymentMethod: false
        )
        let billingAddressElement = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: false)

        let allElements: [Element?] = [
            contactInformationElement,
            billingAddressElement,
        ]
        let autoSectioningElements = allElements.compactMap { $0 }
        return FormElement(autoSectioningElements: autoSectioningElements, theme: theme)
    }
}
