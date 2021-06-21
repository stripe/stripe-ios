//
//  FormElement+Factory.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

extension FormElement {
    static func makeBancontact(merchantDisplayName: String) -> FormElement {
        let name = TextFieldElement.Address.makeName()
        let email = TextFieldElement.Address.makeEmail()
        let mandate = StaticElement(view: SepaMandateView(merchantDisplayName: merchantDisplayName))
        return FormElement(elements: [
            SectionElement(elements: [name]),
            SectionElement(elements: [email]),
            CheckboxElement(didToggle: { selected in
                email.isOptional = !selected
                mandate.isHidden = !selected
            }),
            mandate,
        ]) { params in
            params.paymentMethodParams.type = .bancontact
            params.paymentMethodParams.bancontact = STPPaymentMethodBancontactParams()
            return params
        }
    }
    
    static func makeAlipay() -> FormElement {
        return FormElement(elements: []) { params in
            params.paymentMethodParams.type = .alipay
            return params
        }
    }
}
