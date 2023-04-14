//
//  PersistablePaymentMethodOption.swift
//  StripePaymentsUI
//

import Foundation

@_spi(PrivateBetaSavedPaymentMethodsSheet) public enum PersistablePaymentMethodOptionError: Error {
    case unableToEncode(PersistablePaymentMethodOption)
    case unableToDecode(String?)
}

@objc @_spi(PrivateBetaSavedPaymentMethodsSheet) public class PersistablePaymentMethodOption: NSObject {
    public enum PersistablePaymentMethodOptionType: Codable {
        case applePay
        case link
        // We'd prefer an enum with an associated value for this case, but it needs to remain Objective-C compatible
        case stripe
    }
    public let stripePaymentMethodId: String?
    public let type: PersistablePaymentMethodOptionType
    public var value: String {
        switch type {
        case .applePay:
            return "apple_pay"
        case .link:
            return "link"
        case .stripe:
            return stripePaymentMethodId! // It isn't possible to initialize PersistablePaymentMethodOption with a nil string
        }
    }

    public static func applePay() -> PersistablePaymentMethodOption {
        return PersistablePaymentMethodOption(type: .applePay)
    }
    public static func link() -> PersistablePaymentMethodOption {
        return PersistablePaymentMethodOption(type: .link)
    }

    public static func stripePaymentMethod(_ paymentMethodId: String) -> PersistablePaymentMethodOption {
        return PersistablePaymentMethodOption(stripePaymentMethodId: paymentMethodId)
    }

    public init(value: String) {
        switch value {
        case "apple_pay":
            self.type = .applePay
            self.stripePaymentMethodId = nil
        case "link":
            self.type = .link
            self.stripePaymentMethodId = nil
        default:
            self.type = .stripe
            self.stripePaymentMethodId = value
        }
    }

    private init(type: PersistablePaymentMethodOptionType) {
        self.type = type
        self.stripePaymentMethodId = nil
        assert(type != .stripe) // Can't initialize a Stripe type without an ID string
    }

    private init(stripePaymentMethodId: String) {
        self.type = .stripe
        self.stripePaymentMethodId = stripePaymentMethodId
    }

    /// Sets the default payment method for a given customer.
    /// - Parameters:
    ///   - identifier: Payment method identifier.
    ///   - customerID: ID of the customer. Pass `nil` for anonymous users.
    static public func setDefaultPaymentMethod(_ paymentMethodOption: PersistablePaymentMethodOption, forCustomer customerID: String?) {
        var customerToDefaultPaymentMethodID = UserDefaults.standard.customerToLastSelectedPaymentMethod ?? [:]

        let key = customerID ?? ""
        customerToDefaultPaymentMethodID[key] = paymentMethodOption.value

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

    public override func isEqual(_ object: Any?) -> Bool {
        if object == nil || !(object is PersistablePaymentMethodOption) {
            return false
        }
        if let object = object as? PersistablePaymentMethodOption {
            return (self.value == object.value)
        }
        return false
    }
}
