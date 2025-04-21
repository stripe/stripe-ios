//
//  STPPaymentMethodEnums.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 3/12/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// The type of the PaymentMethod.
@objc public enum STPPaymentMethodType: Int {
    /// A card payment method.
    case card
    /// An Alipay payment method.
    case alipay
    /// A GrabPay payment method.
    case grabPay
    /// An iDEAL payment method.
    @objc(STPPaymentMethodTypeiDEAL) case iDEAL
    /// An FPX payment method.
    case FPX
    /// A card present payment method.
    case cardPresent
    /// A SEPA Debit payment method.
    @objc(STPPaymentMethodTypeSEPADebit) case SEPADebit
    /// An AU BECS Debit payment method.
    @objc(STPPaymentMethodTypeAUBECSDebit) case AUBECSDebit
    /// A Bacs Debit payment method.
    case bacsDebit
    /// A giropay payment method.
    case giropay
    /// A Przelewy24 Debit payment method.
    case przelewy24
    /// An EPS payment method.
    @objc(STPPaymentMethodTypeEPS) case EPS
    /// A Bancontact payment method.
    case bancontact
    /// A NetBanking payment method.
    case netBanking
    /// An OXXO payment method.
    @objc(STPPaymentMethodTypeOXXO) case OXXO
    /// A Sofort payment method.
    case sofort
    /// A UPI payment method.
    case UPI
    /// A PayPal payment method. :nodoc:
    case payPal
    /// An AfterpayClearpay payment method
    case afterpayClearpay
    /// A BLIK payment method
    @objc(STPPaymentMethodTypeBLIK)
    case blik
    /// A WeChat Pay payment method
    case weChatPay
    /// A Boleto payment method.
    case boleto
    /// A Link payment method
    case link
    /// A Klarna payment method.
    case klarna
    /// An Affirm payment method
    case affirm
    /// A US Bank Account payment method (ACH)
    case USBankAccount
    /// A CashApp payment method
    case cashApp
    /// A PayNow payment method
    case paynow
    /// A Zip payment method
    case zip
    /// A RevolutPay payment method
    case revolutPay
    /// An AmazonPay payment method
    case amazonPay
    /// An Alma payment method
    case alma
    /// A Sunbit payment method
    case sunbit
    /// A Billie payment method
    case billie
    /// A Satispay payment method
    case satispay
    /// A Crypto payment method
    case crypto
    /// A MobilePay payment method
    case mobilePay
    /// A Konbini payment method
    case konbini
    /// A PromptPay payment method
    case promptPay
    /// A Swish payment method
    case swish
    /// A TWINT payment method
    case twint
    /// A Multibanco payment method
    case multibanco
    /// An unknown type.
    case unknown

    /// Localized display name for this payment method type
    @_spi(STP) public var displayName: String {
        switch self {
        case .alipay:
            return STPLocalizedString("Alipay", "Payment Method type brand name")
        case .card:
            return STPLocalizedString("Card", "Payment Method for credit card")
        case .iDEAL:
            return STPLocalizedString("iDEAL", "Source type brand name")
        case .FPX:
            return STPLocalizedString("FPX", "Payment Method type brand name")
        case .SEPADebit:
            return STPLocalizedString("SEPA Debit", "Payment method brand name")
        case .AUBECSDebit:
            return STPLocalizedString("AU Direct Debit", "Payment Method type brand name.")
        case .grabPay:
            return STPLocalizedString("GrabPay", "Payment Method type brand name.")
        case .giropay:
            return STPLocalizedString("giropay", "Payment Method type brand name.")
        case .EPS:
            return STPLocalizedString("EPS", "Payment Method type brand name.")
        case .przelewy24:
            return STPLocalizedString("Przelewy24", "Payment Method type brand name.")
        case .bancontact:
            return STPLocalizedString("Bancontact", "Payment Method type brand name")
        case .netBanking:
            return STPLocalizedString("NetBanking", "Payment Method type brand name")
        case .OXXO:
            return STPLocalizedString("OXXO", "Payment Method type brand name")
        case .sofort:
            return STPLocalizedString("Sofort", "Payment Method type brand name")
        case .UPI:
            return STPLocalizedString("UPI", "Payment Method type brand name")
        case .payPal:
            return STPLocalizedString("PayPal", "Payment Method type brand name")
        case .afterpayClearpay:
            return Locale.current.stp_regionCode == "GB" || Locale.current.stp_regionCode == "FR"
                || Locale.current.stp_regionCode == "ES" || Locale.current.stp_regionCode == "IT"
                ? STPLocalizedString("Clearpay", "Payment Method type brand name")
                : STPLocalizedString("Afterpay", "Payment Method type brand name")
        case .blik:
            return STPLocalizedString("BLIK", "Payment Method type brand name")
        case .weChatPay:
            return STPLocalizedString("WeChat Pay", "Payment Method type brand name")
        case .boleto:
            return STPLocalizedString("Boleto", "Payment Method type brand name")
        case .link:
            return STPLocalizedString("Link", "Link Payment Method type brand name")
        case .klarna:
            return STPLocalizedString("Klarna", "Payment Method type brand name")
        case .affirm:
            return STPLocalizedString("Affirm", "Payment Method type brand name")
        case .USBankAccount:
            return STPLocalizedString(
                "US bank account",
                "Payment Method type name for US bank account payments."
            )
        case .cashApp:
            return STPLocalizedString("Cash App Pay", "Payment Method type brand name")
        case .bacsDebit:
            return STPLocalizedString("Bacs Direct Debit", "Payment Method type brand name")
        case .paynow:
            return "PayNow"
        case .zip:
            return "Zip"
        case .revolutPay:
            return "Revolut Pay"
        case .amazonPay:
            return "Amazon Pay"
        case .alma:
            return "Alma"
        case .sunbit:
            return "Sunbit"
        case .billie:
            return "Billie"
        case .satispay:
            return "Satispay"
        case .crypto:
            return "Crypto"
        case .mobilePay:
            return "MobilePay"
        case .konbini:
            return STPLocalizedString("Konbini", "Payment Method type brand name")
        case .promptPay:
            return "PromptPay"
        case .swish:
            return STPLocalizedString("Swish", "Payment Method type brand name")
        case .twint:
            return "TWINT"
        case .multibanco:
            return "Multibanco"
        case .cardPresent,
            .unknown:
            return STPLocalizedString("Unknown", "Default missing source type label")
        @unknown default:
            return STPLocalizedString("Unknown", "Default missing source type label")
        }
    }

    /// The identifier for the payment method type as it is represented on an intent, e.g. "afterpay_clearpay" for Afterpay
    @_spi(STP) public var identifier: String {
        switch self {
        case .card:
            return "card"
        case .alipay:
            return "alipay"
        case .grabPay:
            return "grabpay"
        case .iDEAL:
            return "ideal"
        case .FPX:
            return "fpx"
        case .cardPresent:
            return "card_present"
        case .SEPADebit:
            return "sepa_debit"
        case .AUBECSDebit:
            return "au_becs_debit"
        case .bacsDebit:
            return "bacs_debit"
        case .giropay:
            return "giropay"
        case .przelewy24:
            return "p24"
        case .EPS:
            return "eps"
        case .bancontact:
            return "bancontact"
        case .netBanking:
            return "netbanking"
        case .OXXO:
            return "oxxo"
        case .sofort:
            return "sofort"
        case .UPI:
            return "upi"
        case .payPal:
            return "paypal"
        case .afterpayClearpay:
            return "afterpay_clearpay"
        case .blik:
            return "blik"
        case .weChatPay:
            return "wechat_pay"
        case .boleto:
            return "boleto"
        case .link:
            return "link"
        case .klarna:
            return "klarna"
        case .affirm:
            return "affirm"
        case .USBankAccount:
            return "us_bank_account"
        case .cashApp:
            return "cashapp"
        case .zip:
            return "zip"
        case .unknown:
            return "unknown"
        case .paynow:
            return "paynow"
        case .revolutPay:
            return "revolut_pay"
        case .amazonPay:
            return "amazon_pay"
        case .alma:
            return "alma"
        case .sunbit:
            return "sunbit"
        case .billie:
            return "billie"
        case .satispay:
            return "satispay"
        case .crypto:
            return "crypto"
        case .mobilePay:
            return "mobilepay"
        case .konbini:
            return "konbini"
        case .promptPay:
            return "promptpay"
        case .swish:
            return "swish"
        case .twint:
            return "twint"
        case .multibanco:
            return "multibanco"
        }
    }

    @_spi(STP) public static func fromIdentifier(_ identifier: String) -> STPPaymentMethodType {
        return allCases.first(where: { $0.identifier == identifier }) ?? .unknown
    }

}

extension STPPaymentMethodType: CaseIterable { }

extension STPPaymentMethodType {
    struct PollingRequirement {
        /// - Note: This is a bit hacky. STPPaymentHandlet is hardcoded to poll the Intent status 5 times. `timeBetweenPollingAttempts` controls how long it waits between each poll.
        var timeBetweenPollingAttempts: TimeInterval
    }

    /// If non-nil, Intents with this PM type do not update immediately after the next action is handled and require us to poll and this property contains the information needed to poll.
    var pollingRequirement: PollingRequirement? {
        switch self {
        // Note: Card only requires polling for 3DS2 web-based transactions
        case .card, .amazonPay, .revolutPay:
            return PollingRequirement(timeBetweenPollingAttempts: 3)
        case .swish, .twint:
            // We are intentionally polling for Swish and Twint even though they use the redirect trampoline.
            // The intent is still in `requires_action` status after redirecting following a successful payment (about 50% of the time for Swish).
            // This allows time for the intent to transition to its terminal state.
            return PollingRequirement(timeBetweenPollingAttempts: 1)
        default:
            return nil
        }
    }

    var supportsRefreshing: Bool {
        switch self {
        // Payment methods such as CashApp implement app-to-app redirects that bypass the "redirect trampoline" too give a more seamless user experience for app-to-app.
        // However, when returning to the merchant app in this scenario, the intent often isn't updated instantaneously, requiring us to hit the refresh endpoint.
        // Only a small subset of LPMs support refreshing
        case .cashApp:
            return true
        default:
            return false
        }
    }
}
