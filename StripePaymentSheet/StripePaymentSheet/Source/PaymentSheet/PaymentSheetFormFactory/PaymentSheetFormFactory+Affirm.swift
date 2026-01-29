//
//  PaymentSheetFormFactory+Affirm.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    func makeAffirm() -> PaymentMethodElement {
        let headerElement = SubtitleElement(
            view: AffirmCopyLabel(theme: theme),
            isHorizontalMode: configuration.isHorizontalMode
        )
        return FormElement(elements: [headerElement], theme: theme)
    }
}
