//
//  ConnectionsElement.swift
//  StripePaymentSheet
//
//  Created by Cameron Sabol on 10/27/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit

/// Intentionally empty placeholder for Connections Element
class ConnectionsElement: Element {
    var delegate: ElementDelegate?

    var view: UIView = UIView()
}

// MARK: - PaymentMethodElement
/// :nodoc:
extension ConnectionsElement: PaymentMethodElement {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        // no-op
        return params
    }
}
