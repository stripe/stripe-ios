//
//  PaymentSheetFormFactory+UPI.swift
//  StripeiOS
//
//  Created by Nick Porter on 9/6/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCore

extension PaymentSheetFormFactory {
    
    func makeUPI() -> FormElement {
        return FormElement(autoSectioningElements: [makeUPIHeader(), makeVPAField()], theme: theme)
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
