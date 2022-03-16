//
//  PaymentSheetFormFactory+FormSpec.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 2/15/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    func makeFormElementFromJSONSpecs() -> FormElement? {
        guard
            let paymentMethodType = STPPaymentMethod.string(from: paymentMethod),
            let formSpec = FormSpecProvider.shared.formSpec(for: paymentMethodType)
        else {
            return nil
        }
        let elements = makeFormElements(from: formSpec)
        let formElement = FormElement(autoSectioningElements: elements)
        return formElement
    }
    
    private func makeFormElements(from spec: FormSpec) -> [Element] {
        return spec.elements.map { elementSpec in
            switch elementSpec.type {
            case .name:
                return makeFullName()
            case .email:
                return makeEmail()
            case .address:
                return makeBillingAddressSection()
            }
        }
    }
}
