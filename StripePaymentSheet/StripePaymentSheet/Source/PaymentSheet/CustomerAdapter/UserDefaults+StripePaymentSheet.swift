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
    @_spi(STP) public enum StripePaymentSheetKeys: String {
        /// The key for a dictionary of Customer id to their last selected payment method ID
        case customerToLastSelectedPaymentMethod = "com.stripe.lib:STPStripeCustomerToLastSelectedPaymentMethodKey"
    }

    @_spi(STP) public var customerToLastSelectedPaymentMethod: [String: String]? {
        get {
            let key = StripePaymentSheetKeys.customerToLastSelectedPaymentMethod.rawValue
            return dictionary(forKey: key) as? [String: String]
        }
        set {
            let key = StripePaymentSheetKeys.customerToLastSelectedPaymentMethod.rawValue
            setValue(newValue, forKey: key)
        }
    }

}
