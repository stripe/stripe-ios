//
//  LPMScenario.swift
//  PaymentSheet Example
//

import Foundation
@_spi(InternalOnlyAPI) import StripePayments

/// A playground configuration that makes a single payment method type available in PaymentSheet.
/// Each scenario sets a merchant, currency, and amount the payment method supports, and turns off automatic payment methods so it's the only one offered.
struct LPMScenario: Identifiable {
    typealias Settings = PaymentSheetTestPlaygroundSettings

    /// Who's paying. Most payment methods are offered to guests.
    enum Customer {
        case guest
        /// The merchant's returning customer, authenticated with a CustomerSession
        case returningWithCustomerSession
    }

    let paymentMethodType: STPPaymentMethodType
    let merchantCountry: Settings.MerchantCountry
    let currency: Settings.Currency
    var amount: Settings.Amount = ._5099
    var customer: Customer = .guest

    var id: String { paymentMethodType.identifier }
    var displayName: String { paymentMethodType.displayName }
    var summary: String {
        let summary = "\(merchantCountry.displayName) merchant · \(amount.customDisplayName(currency: currency)) \(currency.rawValue.uppercased())"
        switch customer {
        case .guest:
            return summary
        case .returningWithCustomerSession:
            return "\(summary) · returning customer"
        }
    }

    func apply(to settings: inout Settings) {
        settings.merchantCountryCode = merchantCountry
        settings.currency = currency
        settings.amount = amount
        settings.mode = .payment
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = paymentMethodType.identifier
        settings.allowsDelayedPMs = .on
        // Many payment methods don't support manual capture
        settings.manualCapture = .off
        // PaymentMethod mode adds Link as a payment method type
        settings.linkPassthroughMode = .passthrough
        // Offer only this payment method: no EPMs, CPMs, or payment method configuration
        settings.externalPaymentMethods = .off
        settings.customPaymentMethods = .off
        settings.paymentMethodConfigurationId = nil
        switch customer {
        case .guest:
            // No saved payment methods
            settings.customerMode = .guest
        case .returningWithCustomerSession:
            settings.customerMode = .returning
            settings.customerKeyType = .customerSession
            // Merchants not gated into these CustomerSession features reject them
            settings.paymentMethodRemoveLast = .unset
            settings.paymentMethodSetAsDefault = .unset
        }
        settings.customSecretKey = nil
        settings.customPublishableKey = nil
        settings.customStripeAPI = nil
    }

    func isApplied(to settings: Settings) -> Bool {
        settings.apmsEnabled == .off
            && settings.supportedPaymentMethods == paymentMethodType.identifier
            && settings.merchantCountryCode == merchantCountry
            && settings.currency == currency
    }

    static let all: [LPMScenario] = [
        .init(paymentMethodType: .affirm, merchantCountry: .US, currency: .usd),
        .init(paymentMethodType: .afterpayClearpay, merchantCountry: .US, currency: .usd),
        .init(paymentMethodType: .alipay, merchantCountry: .US, currency: .usd),
        .init(paymentMethodType: .alma, merchantCountry: .FR, currency: .eur),
        .init(paymentMethodType: .amazonPay, merchantCountry: .US, currency: .usd),
        .init(paymentMethodType: .AUBECSDebit, merchantCountry: .AU, currency: .aud),
        .init(paymentMethodType: .bacsDebit, merchantCountry: .GB, currency: .gbp),
        .init(paymentMethodType: .bancontact, merchantCountry: .US, currency: .eur),
        .init(paymentMethodType: .billie, merchantCountry: .DE, currency: .eur),
        .init(paymentMethodType: .bizum, merchantCountry: .FR, currency: .eur),
        .init(paymentMethodType: .blik, merchantCountry: .FR, currency: .pln),
        .init(paymentMethodType: .boleto, merchantCountry: .BR, currency: .brl),
        .init(paymentMethodType: .card, merchantCountry: .US, currency: .usd),
        .init(paymentMethodType: .cashApp, merchantCountry: .US, currency: .usd),
        .init(paymentMethodType: .crypto, merchantCountry: .US, currency: .usd),
        .init(paymentMethodType: .EPS, merchantCountry: .US, currency: .eur),
        .init(paymentMethodType: .FPX, merchantCountry: .MY, currency: .myr),
        .init(paymentMethodType: .gcash, merchantCountry: .US, currency: .php, amount: ._10000),
        .init(paymentMethodType: .goPay, merchantCountry: .US, currency: .idr, amount: ._1000000),
        .init(paymentMethodType: .grabPay, merchantCountry: .SG, currency: .sgd),
        .init(paymentMethodType: .iDEAL, merchantCountry: .US, currency: .eur),
        .init(paymentMethodType: .kakaoPay, merchantCountry: .US, currency: .krw),
        .init(paymentMethodType: .klarna, merchantCountry: .FR, currency: .eur),
        .init(paymentMethodType: .konbini, merchantCountry: .JP, currency: .jpy),
        .init(paymentMethodType: .krCard, merchantCountry: .US, currency: .krw),
        .init(paymentMethodType: .mbWay, merchantCountry: .FR, currency: .eur),
        .init(paymentMethodType: .mobilePay, merchantCountry: .FR, currency: .dkk),
        .init(paymentMethodType: .momo, merchantCountry: .US, currency: .vnd, amount: ._1000000),
        .init(paymentMethodType: .mondu, merchantCountry: .mondu, currency: .eur),
        .init(paymentMethodType: .multibanco, merchantCountry: .US, currency: .eur),
        .init(paymentMethodType: .naverPay, merchantCountry: .US, currency: .krw),
        .init(paymentMethodType: .ngBankTransfer, merchantCountry: .NG, currency: .ngn, amount: ._1000000),
        .init(paymentMethodType: .ngCard, merchantCountry: .NG, currency: .ngn, amount: ._1000000),
        .init(paymentMethodType: .ngUSSD, merchantCountry: .NG, currency: .ngn, amount: ._1000000),
        .init(paymentMethodType: .ngWallet, merchantCountry: .ngWallet, currency: .ngn, amount: ._1000000),
        .init(paymentMethodType: .OXXO, merchantCountry: .MX, currency: .mxn),
        .init(paymentMethodType: .payByBank, merchantCountry: .GB, currency: .gbp),
        .init(paymentMethodType: .payco, merchantCountry: .US, currency: .krw),
        .init(paymentMethodType: .paynow, merchantCountry: .SG, currency: .sgd),
        .init(paymentMethodType: .payPal, merchantCountry: .FR, currency: .eur),
        .init(paymentMethodType: .payPay, merchantCountry: .JP, currency: .jpy),
        .init(paymentMethodType: .pix, merchantCountry: .US, currency: .brl),
        .init(paymentMethodType: .promptPay, merchantCountry: .TH, currency: .thb),
        .init(paymentMethodType: .przelewy24, merchantCountry: .US, currency: .eur),
        .init(paymentMethodType: .qris, merchantCountry: .US, currency: .idr, amount: ._1000000),
        .init(paymentMethodType: .revolutPay, merchantCountry: .GB, currency: .gbp),
        .init(paymentMethodType: .satispay, merchantCountry: .IT, currency: .eur),
        .init(paymentMethodType: .scalapay, merchantCountry: .IT, currency: .eur, amount: ._10000),
        .init(paymentMethodType: .SEPADebit, merchantCountry: .US, currency: .eur),
        .init(paymentMethodType: .sequra, merchantCountry: .ES, currency: .eur, amount: ._10000),
        .init(paymentMethodType: .shopeePay, merchantCountry: .US, currency: .idr, amount: ._1000000),
        // The merchant is gated into Stripe balance, and its returning customer is a v2 Account's backing Customer with a
        // financial account funded in GBP. The small amount keeps that balance from running out.
        .init(paymentMethodType: .stripeBalance, merchantCountry: .stripeBalance, currency: .gbp, amount: ._100, customer: .returningWithCustomerSession),
        .init(paymentMethodType: .sunbit, merchantCountry: .US, currency: .usd, amount: ._10000),
        .init(paymentMethodType: .swish, merchantCountry: .FR, currency: .sek),
        .init(paymentMethodType: .touchNGo, merchantCountry: .US, currency: .myr),
        .init(paymentMethodType: .trueMoney, merchantCountry: .US, currency: .thb, amount: ._10000),
        .init(paymentMethodType: .twint, merchantCountry: .GB, currency: .chf),
        .init(paymentMethodType: .USBankAccount, merchantCountry: .US, currency: .usd),
        .init(paymentMethodType: .vipps, merchantCountry: .FR, currency: .nok),
        .init(paymentMethodType: .wero, merchantCountry: .DE, currency: .eur),
        .init(paymentMethodType: .zip, merchantCountry: .AU, currency: .aud),
    ]
}
