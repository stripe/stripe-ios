//
//  STPPaymentMethodAllowRedisplay.swift
//  StripePayments
//

import Foundation

/// Values for STPPaymentMethodAllowRedisplay
@objc public enum STPPaymentMethodAllowRedisplay: Int {
    /// This is the default value for payment methods where allow_redisplay wasn’t set.
    case unspecified

    /// Use limited to indicate that this payment method can’t always be shown to a customer in a checkout flow. For example, it can only be shown in the context of a specific subscription.
    case limited

    /// Use always to indicate that this payment method can always be shown to a customer in a checkout flow.
    case always

    @_spi(STP) public var stringValue: String? {
        switch self {
        case .unspecified:
            return "unspecified"
        case .limited:
            return "limited"
        case .always:
            return "always"
        }
    }
}

extension STPPaymentMethodAllowRedisplay: CaseIterable { }
