//
//  PaymentSheetFormFactory+AfterpayClearpay.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {

    func makeAfterpayClearpay() -> PaymentMethodElement {
        let header = makeAfterpayClearpayHeader()
        let contactInfoSection = makeContactInformationSection(
            nameRequiredByPaymentMethod: true,
            emailRequiredByPaymentMethod: true,
            phoneRequiredByPaymentMethod: false
        )
        let billingDetails = makeBillingAddressSectionIfNecessary(fullAddressRequiredByPaymentMethod: false)
        return FormElement(autoSectioningElements: [header, contactInfoSection, billingDetails].compactMap { $0 }, theme: theme)
    }

    func makeAfterpayClearpayHeader() -> SubtitleElement {
        let legacyAffirmHeader = SubtitleElement(
            view: AfterpayPriceBreakdownView(
                currency: currency,
                appearance: configuration.appearance
            ),
            isHorizontalMode: paymentMethodOrientation == .horizontal
        )
        return makeBNPLHeader(fallback: legacyAffirmHeader)
    }
}
