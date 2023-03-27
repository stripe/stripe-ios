//
//  SimpleMandateElement.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 3/26/23.
//

@_spi(STP) import StripeUICore
import UIKit

class SimpleMandateElement: PaymentMethodElement {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        if mandateTextView.viewDidAppear {
            params.didDisplayMandate = true
        }
        if customerAlreadySawMandate || mandateTextView.viewDidAppear {
            // the customer must have seen the mandate for this to be valid
            return params
        } else {
            return nil
        }
    }
    
    var delegate: StripeUICore.ElementDelegate?
    var view: UIView {
        return mandateTextView
    }
    let mandateTextView: SimpleMandateTextView
    let customerAlreadySawMandate: Bool
    
    init(mandateText: String, customerAlreadySawMandate: Bool = false, theme: ElementsUITheme = .default) {
        mandateTextView = SimpleMandateTextView(mandateText: mandateText, theme: theme)
        self.customerAlreadySawMandate = customerAlreadySawMandate
    }
}
