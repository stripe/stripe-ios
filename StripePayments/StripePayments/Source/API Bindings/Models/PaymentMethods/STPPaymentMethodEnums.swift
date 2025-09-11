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
    /// A ShopPay payment method
    @_spi(STP) case shopPay
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
        case .shopPay:
            return "ShopPay"
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
        case .shopPay:
            return "shop_pay"
        }
    }

    @_spi(STP) public static func fromIdentifier(_ identifier: String) -> STPPaymentMethodType {
        return allCases.first(where: { $0.identifier == identifier }) ?? .unknown
    }

    @_spi(STP) public static func fromNSNumber(_ nsNumber: NSNumber) -> STPPaymentMethodType {
        return allCases.first(where: { NSNumber(value: $0.rawValue) == nsNumber }) ?? .unknown
    }

}

extension STPPaymentMethodType: CaseIterable { }

extension STPPaymentMethodType {

    /// Manages polling budgets for payment method transactions that require status polling.
    /// Supports both duration-based and count-based budgets to control polling behavior.
    final class PollingBudget {
        /// Defines the type of budget constraint for polling operations.
        enum BudgetType {
            /// Budget based on elapsed time (in seconds)
            case duration(TimeInterval)
            /// Budget based on number of attempts
            case count(Int)
        }

        /// The timestamp when polling started (set when start() is called)
        private var startDate: Date?
        /// The type of budget being enforced
        let budgetType: BudgetType
        /// Current number of polling attempts made
        private(set) var attemptCount: Int = 0
        /// Whether a final poll has been executed
        private(set) var hasPolledFinal: Bool = false
        
        /// Detects if we're running in stub playback mode (HTTPStubs active but not recording)
        private var isTestMode: Bool {
            // Only scale duration when we're using stubs (HTTPStubs present) but not recording (STP_RECORD_NETWORK absent)
            return NSClassFromString("HTTPStubs") != nil && ProcessInfo.processInfo.environment["STP_RECORD_NETWORK"] == nil
        }

        /// Determines if there is remaining budget for additional polling attempts.
        /// Returns false if a final poll has already been executed or budget is exhausted.
        var hasBudgetRemaining: Bool {
            guard !hasPolledFinal else { return false }

            switch budgetType {
            case .duration(let maxDuration):
                guard let startDate = startDate else { return true } // Not started yet
                let elapsed = Date().timeIntervalSince(startDate)
                // Scale duration down for test mode to account for instant stub responses
                let adjustedDuration = isTestMode ? maxDuration * 0.001 : maxDuration
                return elapsed < adjustedDuration
            case .count(let maxAttempts):
                return attemptCount < maxAttempts
            }
        }

        /// Creates a polling budget appropriate for the given payment method type.
        /// Returns nil if the payment method doesn't require polling.
        init?(paymentMethodType: STPPaymentMethodType) {
            switch paymentMethodType {
            case .amazonPay, .revolutPay, .swish, .twint, .przelewy24:
                self.budgetType = .duration(5.0)
            case .card:
                self.budgetType = .duration(15.0)
            default:
                return nil
            }
        }

        /// Creates a polling budget with the specified budget type.
        /// - Parameter budgetType: The budget constraint to apply. Duration must be positive, count must be > 0.
        init(budgetType: BudgetType) {
            switch budgetType {
            case .duration(let timeInterval):
                assert(timeInterval > 0, "Duration must be positive")
            case .count(let count):
                assert(count > 0, "Count must be greater than 0")
            }
            self.budgetType = budgetType
        }

        /// Starts the polling timer. Should be called when polling begins.
        func start() {
            if startDate == nil {
                startDate = Date()
            }
        }

        /// Increments the attempt count. Should be called before each polling attempt.
        func incrementAttempt() {
            attemptCount += 1
        }

        /// Marks the polling as complete. No further attempts will be allowed after this.
        func markAsDone() {
            hasPolledFinal = true
        }
    }

    var supportsRefreshing: Bool {
        switch self {
        // Payment methods such as CashApp implement app-to-app redirects that bypass the "redirect trampoline" too give a more seamless user experience for app-to-app.
        // However, when returning to the merchant app in this scenario, the intent often isn't updated instantaneously, requiring us to hit the refresh endpoint.
        // Only a small subset of LPMs support refreshing
        case .cashApp, .klarna:
            return true
        default:
            return false
        }
    }
}
