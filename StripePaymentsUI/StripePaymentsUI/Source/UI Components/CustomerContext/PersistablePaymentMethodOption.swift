//
//  PersistablePaymentMethodOption.swift
//  StripePaymentsUI
//

public enum PersistablePaymentMethodOptionError: Error {
    case unableToEncode(PersistablePaymentMethodOption)
    case unableToDecode(String?)
}

@objc public class PersistablePaymentMethodOption: NSObject, Codable {
    public enum PersistablePaymentMethodOptionType: Codable {
        case applePay
        case link
        case stripe
    }
    public let stripePaymentMethodId: String?
    public let type: PersistablePaymentMethodOptionType
    public var value: String? {
        switch(type) {
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
}
