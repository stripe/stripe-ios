//
//  BoolReference.swift
//  StripePaymentSheet
//
//  Created by Cameron Sabol on 4/20/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

/// Convenience class to share a reference to a Bool
final class BoolReference {
    var value: Bool = false {
        didSet {
            didUpdate?(value)
        }
    }

    var didUpdate: ((Bool) -> Void)?
}
