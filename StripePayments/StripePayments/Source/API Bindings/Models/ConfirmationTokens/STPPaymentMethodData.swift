//
//  STPConfirmationTokenPaymentMethodData.swift
//  StripePayments
//
//  Created by Nick Porter on 8/25/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

/// An object representing payment method data used to create a ConfirmationToken object.
/// This represents the `payment_method_data` field in the ConfirmationToken API.
/// - seealso: https://stripe.com/docs/api/confirmation_tokens/create#create_confirmation_token-payment_method_data
public class STPPaymentMethodData: NSObject, STPFormEncodable {
    private var _additionalAPIParameters: [AnyHashable: Any] = [:]

    /// The type of payment method.
    @objc public var type: STPPaymentMethodType {
        get {
            return STPPaymentMethod.type(from: rawTypeString ?? "")
        }
        set(newType) {
            if newType != self.type {
                rawTypeString = STPPaymentMethod.string(from: newType)
            }
        }
    }

    /// The raw underlying type string sent to the server.
    /// Generally you should use `type` instead unless you have a reason not to.
    /// You can use this if you want to create a param of a type not yet supported
    /// by the current version of the SDK's `STPPaymentMethodType` enum.
    /// Setting this to a value not known by the SDK causes `type` to
    /// return `STPPaymentMethodTypeUnknown`
    @objc public var rawTypeString: String?

    /// Billing information associated with the PaymentMethod that may be used or required by particular types of payment methods.
    @objc public var billingDetails: STPPaymentMethodBillingDetails?

    /// This field indicates whether this payment method can be shown again to its customer in a checkout flow
    @objc public var allowRedisplay: STPPaymentMethodAllowRedisplay = .unspecified

    /// Set of key-value pairs that you can attach to the PaymentMethod. This can be useful for storing additional information about the PaymentMethod in a structured format.
    @objc public var metadata: [String: String]?

    /// Radar options that may contain HCaptcha token
    @objc var radarOptions: STPRadarOptions?

    // MARK: - Payment Method Type-Specific Properties

    /// If this is a card PaymentMethod, this contains the user's card details.
    @objc public var card: STPPaymentMethodCardParams?
    /// If this is an ACSS Debit PaymentMethod, this contains details about the ACSS Debit payment method.
    @objc public var acssDebit: STPPaymentMethodAUBECSDebitParams? // Using AUBECSDebit as proxy for ACSS Debit structure
    /// If this is an Alipay PaymentMethod, this contains additional details.
    @objc public var alipay: STPPaymentMethodAlipayParams?
    /// If this is an Affirm PaymentMethod, this contains additional details.
    @objc public var affirm: STPPaymentMethodAffirmParams?
    /// If this is an AfterpayClearpay PaymentMethod, this contains additional details.
    @objc public var afterpayClearpay: STPPaymentMethodAfterpayClearpayParams?
    /// If this is an AU BECS Debit PaymentMethod, this contains details about the bank to debit.
    @objc public var auBECSDebit: STPPaymentMethodAUBECSDebitParams?
    /// If this is a Bacs Debit PaymentMethod, this contains details about the bank account to debit.
    @objc public var bacsDebit: STPPaymentMethodBacsDebitParams?
    /// If this is a Bancontact PaymentMethod, this contains additional details.
    @objc public var bancontact: STPPaymentMethodBancontactParams?
    /// If this is a Billie PaymentMethod, this contains additional details.
    @objc public var billie: STPPaymentMethodBillieParams?
    /// If this is a BLIK PaymentMethod, this contains additional details.
    @objc public var blik: STPPaymentMethodBLIKParams?
    /// If this is an Boleto PaymentMethod, this contains additional details.
    @objc public var boleto: STPPaymentMethodBoletoParams?
    /// If this is a Cash App PaymentMethod, this contains additional details.
    @objc public var cashApp: STPPaymentMethodCashAppParams?
    /// If this is a Crypto PaymentMethod, this contains additional details.
    @objc public var crypto: STPPaymentMethodCryptoParams?
    /// If this is an EPS PaymentMethod, this contains additional details.
    @objc public var eps: STPPaymentMethodEPSParams?
    /// If this is a FPX PaymentMethod, this contains details about user's bank.
    @objc public var fpx: STPPaymentMethodFPXParams?
    /// If this is a giropay PaymentMethod, this contains additional details.
    @objc public var giropay: STPPaymentMethodGiropayParams?
    /// If this is a GrabPay PaymentMethod, this contains additional details.
    @objc public var grabPay: STPPaymentMethodGrabPayParams?
    /// If this is a iDEAL PaymentMethod, this contains details about user's bank.
    @objc public var iDEAL: STPPaymentMethodiDEALParams?
    /// If this is a Klarna PaymentMethod, this contains additional details.
    @objc public var klarna: STPPaymentMethodKlarnaParams?
    /// If this is a Link PaymentMethod, this contains additional details
    @objc public var link: STPPaymentMethodLinkParams?
    /// If this is a MobilePay PaymentMethod, this contains additional details.
    @objc public var mobilePay: STPPaymentMethodMobilePayParams?
    /// If this is a Multibanco PaymentMethod, this contains additional details.
    @objc public var multibanco: STPPaymentMethodMultibancoParams?
    /// If this is a NetBanking PaymentMethod, this contains additional details.
    @objc public var netBanking: STPPaymentMethodNetBankingParams?
    /// If this is an OXXO PaymentMethod, this contains additional details.
    @objc public var oxxo: STPPaymentMethodOXXOParams?
    /// If this is a Przelewy24 PaymentMethod, this contains additional details.
    @objc public var przelewy24: STPPaymentMethodPrzelewy24Params?
    /// If this is a PayPal PaymentMethod, this contains additional details.
    @objc public var payPal: STPPaymentMethodPayPalParams?
    /// If this is a RevolutPay PaymentMethod, this contains additional details.
    @objc public var revolutPay: STPPaymentMethodRevolutPayParams?
    /// If this is a Satispay PaymentMethod, this contains additional details.
    @objc public var satispay: STPPaymentMethodSatispayParams?
    /// If this is a SEPA Debit PaymentMethod, this contains details about the bank to debit.
    @objc public var sepaDebit: STPPaymentMethodSEPADebitParams?
    /// If this is a Sofort PaymentMethod, this contains additional details.
    @objc public var sofort: STPPaymentMethodSofortParams?
    /// If this is a Swish PaymentMethod, this contains additional details.
    @objc public var swish: STPPaymentMethodSwishParams?
    /// If this is a UPI PaymentMethod, this contains additional details.
    @objc public var upi: STPPaymentMethodUPIParams?
    /// If this is a US Bank Account PaymentMethod, this contains additional details.
    @objc public var usBankAccount: STPPaymentMethodUSBankAccountParams?
    /// If this is a WeChat Pay PaymentMethod, this contains additional details.
    @objc var weChatPay: STPPaymentMethodWeChatPayParams?

    // MARK: - Convenience Initializers

    /// Creates confirmation token payment method data for a card PaymentMethod.
    /// - Parameters:
    ///   - card: An object containing the user's card details.
    ///   - billingDetails: An object containing the user's billing details.
    ///   - allowRedisplay: An enum defining consent options for redisplay
    ///   - metadata: Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        card: STPPaymentMethodCardParams,
        billingDetails: STPPaymentMethodBillingDetails?,
        allowRedisplay: STPPaymentMethodAllowRedisplay = .unspecified,
        metadata: [String: String]? = nil
    ) {
        self.init()
        self.type = .card
        self.card = card
        self.billingDetails = billingDetails
        self.allowRedisplay = allowRedisplay
        self.metadata = metadata
    }

    /// Creates confirmation token payment method data for a SEPA Debit PaymentMethod.
    /// - Parameters:
    ///   - sepaDebit: An object containing the SEPA bank debit details.
    ///   - billingDetails: An object containing the user's billing details. Note that `billingDetails.name` is required for SEPA Debit PaymentMethods.
    ///   - allowRedisplay: An enum defining consent options for redisplay
    ///   - metadata: Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        sepaDebit: STPPaymentMethodSEPADebitParams,
        billingDetails: STPPaymentMethodBillingDetails,
        allowRedisplay: STPPaymentMethodAllowRedisplay = .unspecified,
        metadata: [String: String]? = nil
    ) {
        self.init()
        self.type = .SEPADebit
        self.sepaDebit = sepaDebit
        self.billingDetails = billingDetails
        self.allowRedisplay = allowRedisplay
        self.metadata = metadata
    }

    /// Creates confirmation token payment method data for a US Bank Account PaymentMethod.
    /// - Parameters:
    ///   - usBankAccount: An object containing additional US bank account details
    ///   - billingDetails: An object containing the user's billing details. Name is required for US Bank Accounts
    ///   - allowRedisplay: An enum defining consent options for redisplay
    ///   - metadata: Additional information to attach to the PaymentMethod
    @objc
    public convenience init(
        usBankAccount: STPPaymentMethodUSBankAccountParams,
        billingDetails: STPPaymentMethodBillingDetails,
        allowRedisplay: STPPaymentMethodAllowRedisplay = .unspecified,
        metadata: [String: String]? = nil
    ) {
        self.init()
        self.type = .USBankAccount
        self.usBankAccount = usBankAccount
        self.billingDetails = billingDetails
        self.allowRedisplay = allowRedisplay
        self.metadata = metadata
    }

    /// Creates confirmation token payment method data from existing payment method parameters.
    /// - Parameter paymentMethodParams: The payment method parameters to convert
    @objc
    public convenience init(from paymentMethodParams: STPPaymentMethodParams) {
        self.init()
        self.type = paymentMethodParams.type
        self.rawTypeString = paymentMethodParams.rawTypeString
        self.billingDetails = paymentMethodParams.billingDetails
        self.allowRedisplay = paymentMethodParams.allowRedisplay
        self.metadata = paymentMethodParams.metadata
        self.radarOptions = paymentMethodParams.radarOptions

        // Copy type-specific parameters
        self.card = paymentMethodParams.card
        self.alipay = paymentMethodParams.alipay
        self.iDEAL = paymentMethodParams.iDEAL
        self.fpx = paymentMethodParams.fpx
        self.sepaDebit = paymentMethodParams.sepaDebit
        self.bacsDebit = paymentMethodParams.bacsDebit
        self.auBECSDebit = paymentMethodParams.auBECSDebit
        self.giropay = paymentMethodParams.giropay
        self.payPal = paymentMethodParams.payPal
        self.przelewy24 = paymentMethodParams.przelewy24
        self.eps = paymentMethodParams.eps
        self.bancontact = paymentMethodParams.bancontact
        self.netBanking = paymentMethodParams.netBanking
        self.oxxo = paymentMethodParams.oxxo
        self.sofort = paymentMethodParams.sofort
        self.upi = paymentMethodParams.upi
        self.grabPay = paymentMethodParams.grabPay
        self.afterpayClearpay = paymentMethodParams.afterpayClearpay
        self.blik = paymentMethodParams.blik
        self.weChatPay = paymentMethodParams.weChatPay
        self.boleto = paymentMethodParams.boleto
        self.link = paymentMethodParams.link
        self.klarna = paymentMethodParams.klarna
        self.affirm = paymentMethodParams.affirm
        self.usBankAccount = paymentMethodParams.usBankAccount
        self.cashApp = paymentMethodParams.cashApp
        self.revolutPay = paymentMethodParams.revolutPay
        self.swish = paymentMethodParams.swish
        self.mobilePay = paymentMethodParams.mobilePay
        self.crypto = paymentMethodParams.crypto
        self.multibanco = paymentMethodParams.multibanco
        self.billie = paymentMethodParams.billie
        self.satispay = paymentMethodParams.satispay
    }

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPConfirmationTokenPaymentMethodData.self), self),
            // ConfirmationToken payment method data details
            "type = \(String(describing: type))",
            "billingDetails = \(String(describing: billingDetails))",
            "allowRedisplay = \(String(describing: allowRedisplay))",
            "metadata = \(String(describing: metadata))",
            "card = \(String(describing: card))",
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPFormEncodable

    @objc
    public static func rootObjectName() -> String? {
        return nil
    }

    @objc
    public static func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: rawTypeString)): "type",
            NSStringFromSelector(#selector(getter: billingDetails)): "billing_details",
            NSStringFromSelector(#selector(getter: allowRedisplayRawString)): "allow_redisplay",
            NSStringFromSelector(#selector(getter: metadata)): "metadata",
            NSStringFromSelector(#selector(getter: radarOptions)): "radar_options",

            // Payment method type-specific fields
            NSStringFromSelector(#selector(getter: card)): "card",
            NSStringFromSelector(#selector(getter: acssDebit)): "acss_debit",
            NSStringFromSelector(#selector(getter: alipay)): "alipay",
            NSStringFromSelector(#selector(getter: affirm)): "affirm",
            NSStringFromSelector(#selector(getter: afterpayClearpay)): "afterpay_clearpay",
            NSStringFromSelector(#selector(getter: auBECSDebit)): "au_becs_debit",
            NSStringFromSelector(#selector(getter: bacsDebit)): "bacs_debit",
            NSStringFromSelector(#selector(getter: bancontact)): "bancontact",
            NSStringFromSelector(#selector(getter: billie)): "billie",
            NSStringFromSelector(#selector(getter: blik)): "blik",
            NSStringFromSelector(#selector(getter: boleto)): "boleto",
            NSStringFromSelector(#selector(getter: cashApp)): "cashapp",
            NSStringFromSelector(#selector(getter: crypto)): "crypto",
            NSStringFromSelector(#selector(getter: eps)): "eps",
            NSStringFromSelector(#selector(getter: fpx)): "fpx",
            NSStringFromSelector(#selector(getter: giropay)): "giropay",
            NSStringFromSelector(#selector(getter: grabPay)): "grabpay",
            NSStringFromSelector(#selector(getter: iDEAL)): "ideal",
            NSStringFromSelector(#selector(getter: klarna)): "klarna",
            NSStringFromSelector(#selector(getter: link)): "link",
            NSStringFromSelector(#selector(getter: mobilePay)): "mobilepay",
            NSStringFromSelector(#selector(getter: multibanco)): "multibanco",
            NSStringFromSelector(#selector(getter: netBanking)): "netbanking",
            NSStringFromSelector(#selector(getter: oxxo)): "oxxo",
            NSStringFromSelector(#selector(getter: przelewy24)): "p24",
            NSStringFromSelector(#selector(getter: payPal)): "paypal",
            NSStringFromSelector(#selector(getter: revolutPay)): "revolut_pay",
            NSStringFromSelector(#selector(getter: satispay)): "satispay",
            NSStringFromSelector(#selector(getter: sepaDebit)): "sepa_debit",
            NSStringFromSelector(#selector(getter: sofort)): "sofort",
            NSStringFromSelector(#selector(getter: swish)): "swish",
            NSStringFromSelector(#selector(getter: upi)): "upi",
            NSStringFromSelector(#selector(getter: usBankAccount)): "us_bank_account",
            NSStringFromSelector(#selector(getter: weChatPay)): "wechat_pay",
        ]
    }

    @objc public var additionalAPIParameters: [AnyHashable: Any] {
        get {
            return _additionalAPIParameters
        }
        set {
            _additionalAPIParameters = newValue
        }
    }

    @objc internal var allowRedisplayRawString: String? {
        return allowRedisplay.stringValue
    }
}
