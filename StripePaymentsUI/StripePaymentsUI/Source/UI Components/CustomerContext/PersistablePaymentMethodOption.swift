//
//  PersistablePaymentMethodOption.swift
//  StripePaymentsUI
//

import Foundation

@_spi(PrivateBetaSavedPaymentMethodsSheet) public enum PersistablePaymentMethodOptionError: Error {
    case unableToEncode(PersistablePaymentMethodOption)
    case unableToDecode(String?)
}

/// A representation of a Payment Method option, used for persisting the user's default payment method.
@_spi(PrivateBetaSavedPaymentMethodsSheet) public enum PersistablePaymentMethodOption: Equatable {
    /// The user's default payment method is Apple Pay.
    /// This is not a specific Apple Pay card. Stripe will present an Apple Pay sheet to the user.
    case applePay
    /// The user's default payment method is Link.
    /// This is not a specific Link payment method. Stripe will present a Link sheet to the user.
    case link
    /// A Stripe payment method backed by a Stripe PaymentMethod ID.
    case stripeId(String)

    @_spi(STP) public init(value: String) {
        switch value {
        case "apple_pay":
            self = .applePay
        case "link":
            self = .link
        default:
            self = .stripeId(value)
        }
    }

    @_spi(STP) public var value: String {
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
    @_spi(STP) public static func setDefaultPaymentMethod(_ paymentMethodOption: PersistablePaymentMethodOption?, forCustomer customerID: String?) {
        var customerToDefaultPaymentMethodID = UserDefaults.standard.customerToLastSelectedPaymentMethod ?? [:]

        let key = customerID ?? ""
        customerToDefaultPaymentMethodID[key] = paymentMethodOption?.value

        UserDefaults.standard.customerToLastSelectedPaymentMethod = customerToDefaultPaymentMethodID
    }

    /// Returns the identifier of the default payment method for a customer.
    /// - Parameter customerID: ID of the customer. Pass `nil` for anonymous users.
    /// - Returns: Default payment method.
    @_spi(STP) public static func defaultPaymentMethod(for customerID: String?) -> PersistablePaymentMethodOption? {
        let key = customerID ?? ""

        guard let value = UserDefaults.standard.customerToLastSelectedPaymentMethod?[key] else {
            return nil
        }

        return PersistablePaymentMethodOption(value: value)
    }
}
