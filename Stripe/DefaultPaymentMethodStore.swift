//
//  DefaultPaymentMethodStore.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 11/6/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// Stores the key we use in NSUserDefaults to save a dictionary of Customer id to their last selected payment method ID
private let userDefaultsKey = "com.stripe.lib:STPStripeCustomerToLastSelectedPaymentMethodKey"

enum DefaultPaymentMethodStore {
    static func saveDefault(paymentMethodID: String?, forCustomer customerID: String) {
        var customerToDefaultPaymentMethodID =
            (UserDefaults.standard.dictionary(forKey: userDefaultsKey))
            as? [String: String] ?? [:]
        customerToDefaultPaymentMethodID[customerID] = paymentMethodID
        UserDefaults.standard.set(
            customerToDefaultPaymentMethodID, forKey: userDefaultsKey)
    }

    static func retrieveDefaultPaymentMethodID(for customerID: String) -> String? {
        let customerToDefaultPaymentMethodID =
            UserDefaults.standard.dictionary(forKey: userDefaultsKey)
            as? [String: String] ?? [:]
        return customerToDefaultPaymentMethodID[customerID]
    }
}
