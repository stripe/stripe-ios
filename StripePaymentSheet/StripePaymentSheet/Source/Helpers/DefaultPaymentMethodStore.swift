//
//  DefaultPaymentMethodStore.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 11/6/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import StripePaymentsUI

final class DefaultPaymentMethodStore {
    enum PaymentMethodIdentifier: Equatable {
        case applePay
        case link
        case stripe(id: String)

        var value: String {
            switch self {
            case .applePay:
                return "apple_pay"
            case .link:
                return "link"
            case .stripe(let id):
                return id
            }
        }

        init(value: String) {
            switch value {
            case "apple_pay":
                self = .applePay
            case "link":
                self = .link
            default:
                self = .stripe(id: value)
            }
        }
    }

    /// Sets the default payment method for a given customer.
    /// - Parameters:
    ///   - identifier: Payment method identifier.
    ///   - customerID: ID of the customer. Pass `nil` for anonymous users.
    static func setDefaultPaymentMethod(_ identifier: PaymentMethodIdentifier, forCustomer customerID: String?) {
        var customerToDefaultPaymentMethodID = UserDefaults.standard.customerToLastSelectedPaymentMethod ?? [:]

        let key = customerID ?? ""
        //Set Default to legacy behavior
        customerToDefaultPaymentMethodID[key] = identifier.value

        if let paymentMethodOption = PersistablePaymentMethodOption(legacyValue: identifier.value) {
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(paymentMethodOption)
                if let data_string = String(data: data, encoding: .utf8) {
                    customerToDefaultPaymentMethodID[key] = data_string
                }
            } catch {
                //no-op
            }
        }
        UserDefaults.standard.customerToLastSelectedPaymentMethod = customerToDefaultPaymentMethodID
    }

    /// Returns the identifier of the default payment method for a customer.
    /// - Parameter customerID: ID of the customer. Pass `nil` for anonymous users.
    /// - Returns: Default payment method.
    static func defaultPaymentMethod(for customerID: String?) -> PaymentMethodIdentifier? {
        let key = customerID ?? ""

        guard let value = UserDefaults.standard.customerToLastSelectedPaymentMethod?[key],
              let data = value.data(using: .utf8) else {
            return nil
        }

        let decoder = JSONDecoder()
        do {
            let decoded = try decoder.decode(PersistablePaymentMethodOption.self, from: data)
            switch(decoded.type) {
            case .applePay:
                return .applePay
            case .link:
                return .link
            case .stripe:
                return .stripe(id: decoded.stripePaymentMethodId ?? "")
            @unknown default:
                assertionFailure("Unaccounted for payment method type")
                return .stripe(id: "")
            }
        } catch {
            return PaymentMethodIdentifier(value: value)
        }
    }
}
