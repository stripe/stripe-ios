//
//  PaymentSheetFormFactory+AfterpayClearpay.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {

    func makeAfterpayClearpay() -> PaymentMethodElement {
        let headerElement = makeAfterpayClearpayHeader()

        // Name and email are required by Afterpay, phone is optional
        let contactInfoSection = makeContactInformationSection(
            nameRequiredByPaymentMethod: true,
            emailRequiredByPaymentMethod: true,
            phoneRequiredByPaymentMethod: false
        )

        let addressElement = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: true)

        let allElements: [Element?] = [
            headerElement,
            contactInfoSection,
            addressElement,
        ]
        let formElement = FormElement(autoSectioningElements: allElements.compactMap { $0 }, theme: theme)
        return makeDefaultsApplierWrapper(for: formElement)
    }

    func makeAfterpayClearpayHeader() -> SubtitleElement {
        return SubtitleElement(
            view: AfterpayPriceBreakdownView(
                currency: currency,
                appearance: configuration.appearance
            ),
            isHorizontalMode: configuration.isHorizontalMode
        )
    }
}
