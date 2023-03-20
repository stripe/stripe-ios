//
//  UserDefaults+Stripe.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 5/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

extension UserDefaults {
    /// Canonical list of all UserDefaults keys the SDK uses
    enum StripeKeys: String {
        /// The key for a dictionary of Customer id to their last selected payment method ID
        case customerToLastSelectedPaymentMethod = "com.stripe.lib:STPStripeCustomerToLastSelectedPaymentMethodKey"
    }

    var customerToLastSelectedPaymentMethod: [String: String]? {
        get {
            let key = StripeKeys.customerToLastSelectedPaymentMethod.rawValue
            return dictionary(forKey: key) as? [String: String]
        }
        set {
            let key = StripeKeys.customerToLastSelectedPaymentMethod.rawValue
            setValue(newValue, forKey: key)
        }
    }

}

