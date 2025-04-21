//
//  CustomerPaymentOption.swift
//  StripePaymentsUI
//

import Foundation

/// A representation of a Payment Method option, used for persisting the user's default payment method.
public enum CustomerPaymentOption: Equatable {
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
    @_spi(STP) public static func setDefaultPaymentMethod(_ paymentMethodOption: CustomerPaymentOption?, forCustomer customerID: String?) {
        var customerToDefaultPaymentMethodID = UserDefaults.standard.customerToLastSelectedPaymentMethod ?? [:]

        let key = customerID ?? ""
        customerToDefaultPaymentMethodID[key] = paymentMethodOption?.value

        UserDefaults.standard.customerToLastSelectedPaymentMethod = customerToDefaultPaymentMethodID
    }

    @_spi(STP) public static func localDefaultPaymentMethod(for customerID: String?) -> CustomerPaymentOption? {
        let key = customerID ?? ""

        guard let value = UserDefaults.standard.customerToLastSelectedPaymentMethod?[key] else {
            return nil
        }

        return CustomerPaymentOption(value: value)
    }

    /// Returns the identifier of the selected by default payment method for a customer.
    /// - Parameter customerID: ID of the customer. Pass `nil` for anonymous users.
    /// - Parameter elementsSession: the ElementsSession.
    /// - Parameter surface: `.paymentSheet` or `.customerSheet`
    /// - Returns: Selected payment method.
    @_spi(STP) public static func selectedPaymentMethod(for customerID: String?, elementsSession: STPElementsSession, surface: HostedSurface) -> CustomerPaymentOption? {
        switch surface {
        case .paymentSheet:
            // if opted in to the "set as default" feature, read from elementsSession
            if elementsSession.paymentMethodSetAsDefaultForPaymentSheet {
                if let defaultPaymentMethod = elementsSession.customer?.getDefaultOrFirstPaymentMethod() {
                    return CustomerPaymentOption.stripeId(defaultPaymentMethod.stripeId)
                }
            }
            // otherwise, get default payment method from local storage
            else {
                return localDefaultPaymentMethod(for: customerID)
            }
        case .customerSheet:
            if elementsSession.paymentMethodSyncDefaultForCustomerSheet {
                if let defaultPaymentMethod = elementsSession.customer?.getDefaultPaymentMethod() {
                    return CustomerPaymentOption.stripeId(defaultPaymentMethod.stripeId)
                }
            } else {
                return localDefaultPaymentMethod(for: customerID)
            }
        }
        return nil
    }
}
