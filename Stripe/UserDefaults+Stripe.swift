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
        /// The key for a dictionary FraudDetectionData dictionary
        case fraudDetectionData = "com.stripe.lib:FraudDetectionDataKey"
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

    var fraudDetectionData: FraudDetectionData? {
        get {
            let key = StripeKeys.fraudDetectionData.rawValue
            guard let data = data(forKey: key) else {
                return nil
            }
            do {
                return try JSONDecoder().decode(FraudDetectionData.self, from: data)
            }
            catch(let e) {
                assertionFailure("\(e)")
                return nil
            }
        }
        set {
            let key = StripeKeys.fraudDetectionData.rawValue
            do {
                let data = try JSONEncoder().encode(newValue)
                setValue(data, forKey: key)
            }
            catch(let e) {
                assertionFailure("\(e)")
                return
            }
        }
    }
}

