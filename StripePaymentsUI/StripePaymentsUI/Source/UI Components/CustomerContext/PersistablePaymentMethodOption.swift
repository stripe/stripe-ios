//
//  PersistablePaymentMethodOption.swift
//  StripePaymentsUI
//

import Foundation

@_spi(STP) @_spi(PrivateBetaSavedPaymentMethodsSheet) public enum PersistablePaymentMethodOptionError: Error {
    case unableToEncode(PersistablePaymentMethodOption)
    case unableToDecode(String?)
}

@objc @_spi(STP) @_spi(PrivateBetaSavedPaymentMethodsSheet) public class PersistablePaymentMethodOption: NSObject, Codable {
    public enum PersistablePaymentMethodOptionType: Codable {
        case applePay
        case link
        case stripe
    }
    public let stripePaymentMethodId: String?
    public let type: PersistablePaymentMethodOptionType
    public var value: String? {
        switch type {
        case .applePay:
            return "apple_pay"
        case .link:
            return "link"
        case .stripe:
            return stripePaymentMethodId
        }
    }

    public static func applePay() -> PersistablePaymentMethodOption {
        return PersistablePaymentMethodOption(type: .applePay, stripePaymentMethodId: nil)
    }
    public static func link() -> PersistablePaymentMethodOption {
        return PersistablePaymentMethodOption(type: .link, stripePaymentMethodId: nil)
    }

    public static func stripePaymentMethod(_ paymentMethodId: String) -> PersistablePaymentMethodOption {
        return PersistablePaymentMethodOption(type: .stripe, stripePaymentMethodId: paymentMethodId)
    }

    public init?(legacyValue: String) {
        switch legacyValue {
        case "apple_pay":
            self.type = .applePay
            self.stripePaymentMethodId = nil
        case "link":
            self.type = .link
            self.stripePaymentMethodId = nil
        default:
            if legacyValue.hasPrefix("pm_") {
                self.type = .stripe
                self.stripePaymentMethodId = legacyValue
            } else {
                 return nil
            }
        }
    }
    private init(type: PersistablePaymentMethodOptionType, stripePaymentMethodId: String?) {
        self.type = type
        self.stripePaymentMethodId = stripePaymentMethodId
    }


    /// Sets the default payment method for a given customer.
    /// - Parameters:
    ///   - identifier: Payment method identifier.
    ///   - customerID: ID of the customer. Pass `nil` for anonymous users.
    static public func setDefaultPaymentMethod(_ paymentMethodOption: PersistablePaymentMethodOption, forCustomer customerID: String?) {
        var customerToDefaultPaymentMethodID = UserDefaults.standard.customerToLastSelectedPaymentMethod ?? [:]

        let key = customerID ?? ""

        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(paymentMethodOption)
            if let data_string = String(data: data, encoding: .utf8) {
                customerToDefaultPaymentMethodID[key] = data_string
            }
        } catch {
            // no-op
        }
        UserDefaults.standard.customerToLastSelectedPaymentMethod = customerToDefaultPaymentMethodID
    }

    /// Returns the identifier of the default payment method for a customer.
    /// - Parameter customerID: ID of the customer. Pass `nil` for anonymous users.
    /// - Returns: Default payment method.
    static public func defaultPaymentMethod(for customerID: String?) -> PersistablePaymentMethodOption? {
        let key = customerID ?? ""

        guard let value = UserDefaults.standard.customerToLastSelectedPaymentMethod?[key],
              let data = value.data(using: .utf8) else {
            return nil
        }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(PersistablePaymentMethodOption.self, from: data)
        } catch {
            return PersistablePaymentMethodOption(legacyValue: value)
        }

    }
}
