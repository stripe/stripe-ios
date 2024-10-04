//
//  SimpleMandateElement.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 3/26/23.
//

@_spi(STP) import StripeUICore
import UIKit

class SimpleMandateElement: PaymentMethodElement {
    let collectsUserInput: Bool = false

    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        // Per the contract of the `updateParams(params:)` API (see its docstring), we should only return a non-nil params if we are valid.
        // We are only valid if the customer saw the mandate - either our view was displayed *or* the customer already saw the view
        // This handles edge cases around the payment method being updated to include or not include a mandate e.g. going from payment -> setup mode. See the `testAppliesPreviousCustomerInput_for_mandate` test for an example.
        if customerAlreadySawMandate || mandateTextView.viewDidAppear {
            params.didDisplayMandate = true
            return params
        } else {
            return nil
        }
    }
    var validationState: ElementValidationState {
        if customerAlreadySawMandate || mandateTextView.viewDidAppear {
            return .valid
        } else {
            return .invalid(error: MandateNotDisplayedError(), shouldDisplay: false)
        }
    }

    var delegate: StripeUICore.ElementDelegate?
    var view: UIView {
        return mandateTextView
    }
    let mandateTextView: SimpleMandateTextView
    let customerAlreadySawMandate: Bool

    init(mandateText: String, customerAlreadySawMandate: Bool, theme: ElementsAppearance = .default) {
        mandateTextView = SimpleMandateTextView(mandateText: mandateText, theme: theme)
        self.customerAlreadySawMandate = customerAlreadySawMandate
    }

    struct MandateNotDisplayedError: ElementValidationError { }
}
