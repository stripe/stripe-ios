//
//  PersistablePaymentMethodOption.swift
//  StripePaymentsUI
//

import Foundation

@_spi(PrivateBetaSavedPaymentMethodsSheet) public enum PersistablePaymentMethodOptionError: Error {
    case unableToEncode(PersistablePaymentMethodOption)
    case unableToDecode(String?)
}

@_spi(PrivateBetaSavedPaymentMethodsSheet) public enum PersistablePaymentMethodOption: Equatable {
    case applePay
    case link
    case stripeId(String)

    public init(value: String) {
        switch value {
        case "apple_pay":
            self = .applePay
        case "link":
            self = .link
        default:
            self = .stripeId(value)
        }
    }

    public var value: String {
        switch self {
        case .applePay:
            return "apple_pay"
        case .link:
            return "link"
        case .stripeId(let stripeId):
            return stripeId
        }
    }
    
    /// Sets the default payment method for a given customer.
    /// - Parameters:
    ///   - identifier: Payment method identifier.
    ///   - customerID: ID of the customer. Pass `nil` for anonymous users.
    static public func setDefaultPaymentMethod(_ paymentMethodOption: PersistablePaymentMethodOption?, forCustomer customerID: String?) {
        var customerToDefaultPaymentMethodID = UserDefaults.standard.customerToLastSelectedPaymentMethod ?? [:]

        let key = customerID ?? ""
        customerToDefaultPaymentMethodID[key] = paymentMethodOption?.value

        UserDefaults.standard.customerToLastSelectedPaymentMethod = customerToDefaultPaymentMethodID
    }

    /// Returns the identifier of the default payment method for a customer.
    /// - Parameter customerID: ID of the customer. Pass `nil` for anonymous users.
    /// - Returns: Default payment method.
    static public func defaultPaymentMethod(for customerID: String?) -> PersistablePaymentMethodOption? {
        let key = customerID ?? ""

        guard let value = UserDefaults.standard.customerToLastSelectedPaymentMethod?[key] else {
            return nil
        }

        return PersistablePaymentMethodOption(value: value)
    }
}
