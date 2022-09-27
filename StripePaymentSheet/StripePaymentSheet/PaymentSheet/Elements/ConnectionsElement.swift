//
//  Connections.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 10/27/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

/// Intentionally empty placeholder for Connections Element
class ConnectionsElement: Element {
    var delegate: ElementDelegate? = nil
    
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
