//
//  STPPaymentMethodRemove.swift
//  StripePaymentSheet
//

enum STPPaymentMethodRemove {
    case enabled
    case disabled
    case partial

    static func paymentMethodRemove(from value: String) -> STPPaymentMethodRemove {
        if value == "enabled" {
            return .enabled
        } else if value == "disabled" {
            return .disabled
        } else if value == "partial" {
            return .partial
        }
        return .disabled
    }
}
