//
//  DefaultPaymentMethodStore.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 11/6/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

struct DefaultPaymentMethodStore {
    static func saveDefault(paymentMethodID: String?, forCustomer customerID: String) {
        var customerToDefaultPaymentMethodID = UserDefaults.standard.customerToLastSelectedPaymentMethod ?? [:]
        customerToDefaultPaymentMethodID[customerID] = paymentMethodID
        UserDefaults.standard.customerToLastSelectedPaymentMethod = customerToDefaultPaymentMethodID
    }

    static func retrieveDefaultPaymentMethodID(for customerID: String) -> String? {
        let customerToDefaultPaymentMethodID = UserDefaults.standard.customerToLastSelectedPaymentMethod ?? [:]
        return customerToDefaultPaymentMethodID[customerID]
    }
}
