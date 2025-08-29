//
//  STPConfirmationToken.swift
//  StripePayments
//
//  Created by Nick Porter on 8/25/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

/// ConfirmationToken objects represent your customer's payment details. They can be used with PaymentIntents and SetupIntents to collect payments.
/// - seealso: https://stripe.com/docs/api/confirmation_tokens
public class STPConfirmationToken: NSObject, STPAPIResponseDecodable {
    /// Unique identifier for the object (e.g. `ctoken_...`).
    @objc private(set) public var stripeId: String

    /// String representing the object's type. Always `"confirmation_token"`.
    @objc private(set) public var object: String

    /// Time at which the object was created. Measured in seconds since the Unix epoch.
    @objc private(set) public var created: Date

    /// Time at which this ConfirmationToken expires and can no longer be used to confirm a PaymentIntent or SetupIntent.
    @objc private(set) public var expiresAt: Date?

    /// `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    @objc private(set) public var liveMode = false

    /// Data used for generating a Mandate.
    private(set) public var mandateData: STPConfirmationToken.MandateData?

    /// ID of the PaymentIntent this token was used to confirm.
    @objc private(set) public var paymentIntentId: String?

    /// ID of the SetupIntent this token was used to confirm.
    @objc private(set) public var setupIntentId: String?

    /// Payment-method-specific configuration captured on the token.
    private(set) public var paymentMethodOptions: STPConfirmationToken.PaymentMethodOptions?

    /// Non-PII preview of payment details captured by the Payment Element.
    private(set) public var paymentMethodPreview: STPConfirmationToken.PaymentMethodPreview?

    /// Return URL used to confirm the intent for redirect-based methods.
    @objc private(set) public var returnURL: String?

    /// Indicates intent to reuse the payment method.
    @objc private(set) public var setupFutureUsage: STPPaymentIntentSetupFutureUsage

    /// Shipping information collected on this token.
    @objc private(set) public var shipping: STPPaymentIntentShippingDetails?

    /// Indicates whether Stripe SDK is used to handle confirmation flow.
    @objc private(set) public var useStripeSDK = false

    /// :nodoc:
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPConfirmationToken.self), self),
            // Identifier
            "stripeId = \(stripeId)",
            // ConfirmationToken details
            "object = \(object)",
            "created = \(String(describing: created))",
            "expiresAt = \(String(describing: expiresAt))",
            "liveMode = \(liveMode)",
            "mandateData = \(String(describing: mandateData))",
            "paymentIntentId = \(paymentIntentId ?? "")",
            "setupIntentId = \(setupIntentId ?? "")",
            "paymentMethodOptions = \(String(describing: paymentMethodOptions))",
            "paymentMethodPreview = \(String(describing: paymentMethodPreview))",
            "returnURL = \(returnURL ?? "")",
            "setupFutureUsage = \(String(describing: setupFutureUsage))",
            "shipping = \(String(describing: shipping))",
            "useStripeSDK = \(useStripeSDK)",
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    internal init(
        stripeId: String,
        object: String,
        created: Date,
        expiresAt: Date?,
        liveMode: Bool,
        mandateData: STPConfirmationToken.MandateData?,
        paymentIntentId: String?,
        setupIntentId: String?,
        paymentMethodOptions: STPConfirmationToken.PaymentMethodOptions?,
        paymentMethodPreview: STPConfirmationToken.PaymentMethodPreview?,
        returnURL: String?,
        setupFutureUsage: STPPaymentIntentSetupFutureUsage,
        shipping: STPPaymentIntentShippingDetails?,
        useStripeSDK: Bool,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.stripeId = stripeId
        self.object = object
        self.created = created
        self.expiresAt = expiresAt
        self.liveMode = liveMode
        self.mandateData = mandateData
        self.paymentIntentId = paymentIntentId
        self.setupIntentId = setupIntentId
        self.paymentMethodOptions = paymentMethodOptions
        self.paymentMethodPreview = paymentMethodPreview
        self.returnURL = returnURL
        self.setupFutureUsage = setupFutureUsage
        self.shipping = shipping
        self.useStripeSDK = useStripeSDK
        self.allResponseFields = allResponseFields
        super.init()
    }

    // MARK: - STPAPIResponseDecodable
    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response,
              let stripeId = response["id"] as? String,
              let object = response["object"] as? String,
              let createdTimestamp = response["created"] as? TimeInterval else {
            return nil
        }

        let created = Date(timeIntervalSince1970: createdTimestamp)
        let expiresAt = (response["expires_at"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
        let liveMode = response["livemode"] as? Bool ?? false
        let paymentIntentId = response["payment_intent"] as? String
        let setupIntentId = response["setup_intent"] as? String
        let returnURL = response["return_url"] as? String
        let useStripeSDK = response["use_stripe_sdk"] as? Bool ?? false

        var setupFutureUsage: STPPaymentIntentSetupFutureUsage = .none
        if let setupFutureUsageString = response["setup_future_usage"] as? String {
            setupFutureUsage = STPPaymentIntentSetupFutureUsage.init(string: setupFutureUsageString)
        }

        var mandateData: STPConfirmationToken.MandateData?
        if let mandateDataDict = response["mandate_data"] as? [AnyHashable: Any] {
            mandateData = STPConfirmationToken.MandateData.decodedObject(fromAPIResponse: mandateDataDict)
        }

        var paymentMethodOptions: STPConfirmationToken.PaymentMethodOptions?
        if let paymentMethodOptionsDict = response["payment_method_options"] as? [AnyHashable: Any] {
            paymentMethodOptions = STPConfirmationToken.PaymentMethodOptions.decodedObject(fromAPIResponse: paymentMethodOptionsDict)
        }

        var paymentMethodPreview: STPConfirmationToken.PaymentMethodPreview?
        if let paymentMethodPreviewDict = response["payment_method_preview"] as? [AnyHashable: Any] {
            paymentMethodPreview = STPConfirmationToken.PaymentMethodPreview.decodedObject(fromAPIResponse: paymentMethodPreviewDict)
        }

        var shipping: STPPaymentIntentShippingDetails?
        if let shippingDict = response["shipping"] as? [AnyHashable: Any] {
            shipping = STPPaymentIntentShippingDetails.decodedObject(fromAPIResponse: shippingDict)
        }

        return STPConfirmationToken(
            stripeId: stripeId,
            object: object,
            created: created,
            expiresAt: expiresAt,
            liveMode: liveMode,
            mandateData: mandateData,
            paymentIntentId: paymentIntentId,
            setupIntentId: setupIntentId,
            paymentMethodOptions: paymentMethodOptions,
            paymentMethodPreview: paymentMethodPreview,
            returnURL: returnURL,
            setupFutureUsage: setupFutureUsage,
            shipping: shipping,
            useStripeSDK: useStripeSDK,
            allResponseFields: response
        ) as? Self
    }
}

// MARK: - Nested Types

extension STPConfirmationToken {
    /// Mandate data associated with the ConfirmationToken.
    public struct MandateData: Equatable {
        /// Customer acceptance information for the mandate.
        public let customerAcceptance: MandateCustomerAcceptance

        static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> MandateData? {
            guard let response = response,
                  let customerAcceptanceDict = response["customer_acceptance"] as? [AnyHashable: Any],
                  let customerAcceptance = MandateCustomerAcceptance.decodedObject(fromAPIResponse: customerAcceptanceDict) else {
                return nil
            }

            return MandateData(customerAcceptance: customerAcceptance)
        }
    }

    /// Customer acceptance information for the mandate.
    public struct MandateCustomerAcceptance: Equatable {
        /// The type of customer acceptance information.
        public let type: String
        /// Online acceptance details if accepted online.
        public let online: MandateOnline?

        static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> MandateCustomerAcceptance? {
            guard let response = response,
                  let type = response["type"] as? String else {
                return nil
            }

            var online: MandateOnline?
            if let onlineDict = response["online"] as? [AnyHashable: Any] {
                online = MandateOnline.decodedObject(fromAPIResponse: onlineDict)
            }

            return MandateCustomerAcceptance(type: type, online: online)
        }
    }

    /// Online acceptance details for the mandate.
    public struct MandateOnline: Equatable {
        /// IP address of the customer when they accepted the mandate.
        public let ipAddress: String?
        /// User agent of the customer when they accepted the mandate.
        public let userAgent: String?

        static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> MandateOnline? {
            guard let response = response else {
                return nil
            }

            let ipAddress = response["ip_address"] as? String
            let userAgent = response["user_agent"] as? String

            return MandateOnline(ipAddress: ipAddress, userAgent: userAgent)
        }
    }

    /// Payment-method-specific configuration for the ConfirmationToken.
    public struct PaymentMethodOptions: Equatable {
        /// Card-specific options.
        public let card: CardOptions?

        static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> PaymentMethodOptions? {
            guard let response = response else {
                return nil
            }

            var card: CardOptions?
            if let cardDict = response["card"] as? [AnyHashable: Any] {
                card = CardOptions.decodedObject(fromAPIResponse: cardDict)
            }

            return PaymentMethodOptions(card: card)
        }
    }

    /// Card-specific options for the ConfirmationToken.
    public struct CardOptions: Equatable {
        /// CVC token for the card.
        public let cvcToken: String?
        /// Installment configuration for the card.
        public let installments: CardInstallments?

        static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> CardOptions? {
            guard let response = response else {
                return nil
            }

            let cvcToken = response["cvc_token"] as? String

            var installments: CardInstallments?
            if let installmentsDict = response["installments"] as? [AnyHashable: Any] {
                installments = CardInstallments.decodedObject(fromAPIResponse: installmentsDict)
            }

            return CardOptions(cvcToken: cvcToken, installments: installments)
        }
    }

    /// Card installment configuration.
    public struct CardInstallments: Equatable {
        /// Installment plan configuration.
        public let plan: CardInstallmentsPlan?

        static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> CardInstallments? {
            guard let response = response else {
                return nil
            }

            var plan: CardInstallmentsPlan?
            if let planDict = response["plan"] as? [AnyHashable: Any] {
                plan = CardInstallmentsPlan.decodedObject(fromAPIResponse: planDict)
            }

            return CardInstallments(plan: plan)
        }
    }

    /// Card installment plan configuration.
    public struct CardInstallmentsPlan: Equatable {
        /// Interval for installment payments.
        public enum Interval: String { case month }
        /// Type of installment plan.
        public enum PlanType: String { case fixedCount = "fixed_count", bonus, revolving }

        /// Number of installments.
        public let count: Int?
        /// Interval between installments.
        public let interval: Interval?
        /// Type of installment plan.
        public let type: PlanType

        static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> CardInstallmentsPlan? {
            guard let response = response,
                  let typeString = response["type"] as? String,
                  let type = PlanType(rawValue: typeString) else {
                return nil
            }

            let count = response["count"] as? Int

            var interval: Interval?
            if let intervalString = response["interval"] as? String {
                interval = Interval(rawValue: intervalString)
            }

            return CardInstallmentsPlan(count: count, interval: interval, type: type)
        }
    }

    /// Preview of payment method details captured by the ConfirmationToken.
    public struct PaymentMethodPreview: Equatable {
        /// Type of the payment method.
        public let type: STPPaymentMethodType
        /// Billing details for the payment method.
        public let billingDetails: STPPaymentMethodBillingDetails?
        /// This field indicates whether this payment method can be shown again to its customer in a checkout flow
        public let allowRedisplay: STPPaymentMethodAllowRedisplay
        /// The ID of the Customer to which this PaymentMethod is saved. Nil when the PaymentMethod has not been saved to a Customer.
        public let customerId: String?

        // Payment method type-specific properties
        /// If this is a card PaymentMethod, this contains additional details.
        public let card: STPPaymentMethodCard?
        /// If this is an Alipay PaymentMethod, this contains additional details.
        public let alipay: STPPaymentMethodAlipay?
        /// If this is a GrabPay PaymentMethod, this contains additional details.
        public let grabPay: STPPaymentMethodGrabPay?
        /// If this is a iDEAL PaymentMethod, this contains additional details.
        public let iDEAL: STPPaymentMethodiDEAL?
        /// If this is an FPX PaymentMethod, this contains additional details.
        public let fpx: STPPaymentMethodFPX?
        /// If this is a card present PaymentMethod, this contains additional details.
        public let cardPresent: STPPaymentMethodCardPresent?
        /// If this is a SEPA Debit PaymentMethod, this contains additional details.
        public let sepaDebit: STPPaymentMethodSEPADebit?
        /// If this is a Bacs Debit PaymentMethod, this contains additional details.
        public let bacsDebit: STPPaymentMethodBacsDebit?
        /// If this is an AU BECS Debit PaymentMethod, this contains additional details.
        public let auBECSDebit: STPPaymentMethodAUBECSDebit?
        /// If this is a giropay PaymentMethod, this contains additional details.
        public let giropay: STPPaymentMethodGiropay?
        /// If this is an EPS PaymentMethod, this contains additional details.
        public let eps: STPPaymentMethodEPS?
        /// If this is a Przelewy24 PaymentMethod, this contains additional details.
        public let przelewy24: STPPaymentMethodPrzelewy24?
        /// If this is a Bancontact PaymentMethod, this contains additional details.
        public let bancontact: STPPaymentMethodBancontact?
        /// If this is a NetBanking PaymentMethod, this contains additional details.
        public let netBanking: STPPaymentMethodNetBanking?
        /// If this is an OXXO PaymentMethod, this contains additional details.
        public let oxxo: STPPaymentMethodOXXO?
        /// If this is a Sofort PaymentMethod, this contains additional details.
        public let sofort: STPPaymentMethodSofort?
        /// If this is a UPI PaymentMethod, this contains additional details.
        public let upi: STPPaymentMethodUPI?
        /// If this is a PayPal PaymentMethod, this contains additional details.
        public let payPal: STPPaymentMethodPayPal?
        /// If this is an AfterpayClearpay PaymentMethod, this contains additional details.
        public let afterpayClearpay: STPPaymentMethodAfterpayClearpay?
        /// If this is a BLIK PaymentMethod, this contains additional details.
        public let blik: STPPaymentMethodBLIK?
        /// If this is a WeChat Pay PaymentMethod, this contains additional details.
        internal let weChatPay: STPPaymentMethodWeChatPay?
        /// If this is a Boleto PaymentMethod, this contains additional details.
        public let boleto: STPPaymentMethodBoleto?
        /// If this is a Link PaymentMethod, this contains additional details.
        public let link: STPPaymentMethodLink?
        /// If this is a Klarna PaymentMethod, this contains additional details.
        public let klarna: STPPaymentMethodKlarna?
        /// If this is an Affirm PaymentMethod, this contains additional details.
        public let affirm: STPPaymentMethodAffirm?
        /// If this is a US Bank Account PaymentMethod, this contains additional details.
        public let usBankAccount: STPPaymentMethodUSBankAccount?
        /// If this is a Cash App PaymentMethod, this contains additional details.
        public let cashApp: STPPaymentMethodCashApp?
        /// If this is a Revolut Pay PaymentMethod, this contains additional details.
        public let revolutPay: STPPaymentMethodRevolutPay?
        /// If this is a Swish PaymentMethod, this contains additional details.
        public let swish: STPPaymentMethodSwish?
        /// If this is an Amazon Pay PaymentMethod, this contains additional details.
        public let amazonPay: STPPaymentMethodAmazonPay?
        /// If this is an Alma PaymentMethod, this contains additional details.
        public let alma: STPPaymentMethodAlma?
        /// If this is a Sunbit PaymentMethod, this contains additional details.
        public let sunbit: STPPaymentMethodSunbit?
        /// If this is a Billie PaymentMethod, this contains additional details.
        public let billie: STPPaymentMethodBillie?
        /// If this is a Satispay PaymentMethod, this contains additional details.
        public let satispay: STPPaymentMethodSatispay?
        /// If this is a Crypto PaymentMethod, this contains additional details.
        public let crypto: STPPaymentMethodCrypto?
        /// If this is a Multibanco PaymentMethod, this contains additional details.
        public let multibanco: STPPaymentMethodMultibanco?
        /// If this is a MobilePay PaymentMethod, this contains additional details.
        public let mobilePay: STPPaymentMethodMobilePay?

        internal init(
            type: STPPaymentMethodType,
            billingDetails: STPPaymentMethodBillingDetails?,
            allowRedisplay: STPPaymentMethodAllowRedisplay = .unspecified,
            customerId: String? = nil,
            card: STPPaymentMethodCard? = nil,
            alipay: STPPaymentMethodAlipay? = nil,
            grabPay: STPPaymentMethodGrabPay? = nil,
            iDEAL: STPPaymentMethodiDEAL? = nil,
            fpx: STPPaymentMethodFPX? = nil,
            cardPresent: STPPaymentMethodCardPresent? = nil,
            sepaDebit: STPPaymentMethodSEPADebit? = nil,
            bacsDebit: STPPaymentMethodBacsDebit? = nil,
            auBECSDebit: STPPaymentMethodAUBECSDebit? = nil,
            giropay: STPPaymentMethodGiropay? = nil,
            eps: STPPaymentMethodEPS? = nil,
            przelewy24: STPPaymentMethodPrzelewy24? = nil,
            bancontact: STPPaymentMethodBancontact? = nil,
            netBanking: STPPaymentMethodNetBanking? = nil,
            oxxo: STPPaymentMethodOXXO? = nil,
            sofort: STPPaymentMethodSofort? = nil,
            upi: STPPaymentMethodUPI? = nil,
            payPal: STPPaymentMethodPayPal? = nil,
            afterpayClearpay: STPPaymentMethodAfterpayClearpay? = nil,
            blik: STPPaymentMethodBLIK? = nil,
            weChatPay: STPPaymentMethodWeChatPay? = nil,
            boleto: STPPaymentMethodBoleto? = nil,
            link: STPPaymentMethodLink? = nil,
            klarna: STPPaymentMethodKlarna? = nil,
            affirm: STPPaymentMethodAffirm? = nil,
            usBankAccount: STPPaymentMethodUSBankAccount? = nil,
            cashApp: STPPaymentMethodCashApp? = nil,
            revolutPay: STPPaymentMethodRevolutPay? = nil,
            swish: STPPaymentMethodSwish? = nil,
            amazonPay: STPPaymentMethodAmazonPay? = nil,
            alma: STPPaymentMethodAlma? = nil,
            sunbit: STPPaymentMethodSunbit? = nil,
            billie: STPPaymentMethodBillie? = nil,
            satispay: STPPaymentMethodSatispay? = nil,
            crypto: STPPaymentMethodCrypto? = nil,
            multibanco: STPPaymentMethodMultibanco? = nil,
            mobilePay: STPPaymentMethodMobilePay? = nil
        ) {
            self.type = type
            self.billingDetails = billingDetails
            self.allowRedisplay = allowRedisplay
            self.customerId = customerId
            self.card = card
            self.alipay = alipay
            self.grabPay = grabPay
            self.iDEAL = iDEAL
            self.fpx = fpx
            self.cardPresent = cardPresent
            self.sepaDebit = sepaDebit
            self.bacsDebit = bacsDebit
            self.auBECSDebit = auBECSDebit
            self.giropay = giropay
            self.eps = eps
            self.przelewy24 = przelewy24
            self.bancontact = bancontact
            self.netBanking = netBanking
            self.oxxo = oxxo
            self.sofort = sofort
            self.upi = upi
            self.payPal = payPal
            self.afterpayClearpay = afterpayClearpay
            self.blik = blik
            self.weChatPay = weChatPay
            self.boleto = boleto
            self.link = link
            self.klarna = klarna
            self.affirm = affirm
            self.usBankAccount = usBankAccount
            self.cashApp = cashApp
            self.revolutPay = revolutPay
            self.swish = swish
            self.amazonPay = amazonPay
            self.alma = alma
            self.sunbit = sunbit
            self.billie = billie
            self.satispay = satispay
            self.crypto = crypto
            self.multibanco = multibanco
            self.mobilePay = mobilePay
        }

        static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> PaymentMethodPreview? {
            guard let response = response,
                  let typeString = response["type"] as? String else {
                return nil
            }

            let dict = response.stp_dictionaryByRemovingNulls()
            let type = STPPaymentMethod.type(from: typeString)

            var billingDetails: STPPaymentMethodBillingDetails?
            if let billingDetailsDict = dict.stp_dictionary(forKey: "billing_details") {
                billingDetails = STPPaymentMethodBillingDetails.decodedObject(fromAPIResponse: billingDetailsDict)
            }

            let allowRedisplay = STPPaymentMethod.allowRedisplay(from: dict.stp_string(forKey: "allow_redisplay") ?? "")
            let customerId = dict.stp_string(forKey: "customer")

            // Parse type-specific payment method details using existing decoders
            let card = STPPaymentMethodCard.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "card"))
            let alipay = STPPaymentMethodAlipay.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "alipay"))
            let grabPay = STPPaymentMethodGrabPay.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "grabpay"))
            let iDEAL = STPPaymentMethodiDEAL.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "ideal"))
            let fpx = STPPaymentMethodFPX.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "fpx"))
            let cardPresent = STPPaymentMethodCardPresent.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "card_present"))
            let sepaDebit = STPPaymentMethodSEPADebit.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "sepa_debit"))
            let bacsDebit = STPPaymentMethodBacsDebit.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "bacs_debit"))
            let auBECSDebit = STPPaymentMethodAUBECSDebit.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "au_becs_debit"))
            let giropay = STPPaymentMethodGiropay.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "giropay"))
            let eps = STPPaymentMethodEPS.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "eps"))
            let przelewy24 = STPPaymentMethodPrzelewy24.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "p24"))
            let bancontact = STPPaymentMethodBancontact.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "bancontact"))
            let netBanking = STPPaymentMethodNetBanking.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "netbanking"))
            let oxxo = STPPaymentMethodOXXO.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "oxxo"))
            let sofort = STPPaymentMethodSofort.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "sofort"))
            let upi = STPPaymentMethodUPI.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "upi"))
            let payPal = STPPaymentMethodPayPal.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "paypal"))
            let afterpayClearpay = STPPaymentMethodAfterpayClearpay.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "afterpay_clearpay"))
            let blik = STPPaymentMethodBLIK.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "blik"))
            let weChatPay = STPPaymentMethodWeChatPay.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "wechat_pay"))
            let boleto = STPPaymentMethodBoleto.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "boleto"))
            let link = STPPaymentMethodLink.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "link"))
            let klarna = STPPaymentMethodKlarna.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "klarna"))
            let affirm = STPPaymentMethodAffirm.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "affirm"))
            let usBankAccount = STPPaymentMethodUSBankAccount.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "us_bank_account"))
            let cashApp = STPPaymentMethodCashApp.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "cashapp"))
            let revolutPay = STPPaymentMethodRevolutPay.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "revolut_pay"))
            let swish = STPPaymentMethodSwish.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "swish"))
            let amazonPay = STPPaymentMethodAmazonPay.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "amazon_pay"))
            let alma = STPPaymentMethodAlma.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "alma"))
            let sunbit = STPPaymentMethodSunbit.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "sunbit"))
            let billie = STPPaymentMethodBillie.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "billie"))
            let satispay = STPPaymentMethodSatispay.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "satispay"))
            let crypto = STPPaymentMethodCrypto.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "crypto"))
            let multibanco = STPPaymentMethodMultibanco.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "multibanco"))
            let mobilePay = STPPaymentMethodMobilePay.decodedObject(fromAPIResponse: dict.stp_dictionary(forKey: "mobilepay"))

            return PaymentMethodPreview(
                type: type,
                billingDetails: billingDetails,
                allowRedisplay: allowRedisplay,
                customerId: customerId,
                card: card,
                alipay: alipay,
                grabPay: grabPay,
                iDEAL: iDEAL,
                fpx: fpx,
                cardPresent: cardPresent,
                sepaDebit: sepaDebit,
                bacsDebit: bacsDebit,
                auBECSDebit: auBECSDebit,
                giropay: giropay,
                eps: eps,
                przelewy24: przelewy24,
                bancontact: bancontact,
                netBanking: netBanking,
                oxxo: oxxo,
                sofort: sofort,
                upi: upi,
                payPal: payPal,
                afterpayClearpay: afterpayClearpay,
                blik: blik,
                weChatPay: weChatPay,
                boleto: boleto,
                link: link,
                klarna: klarna,
                affirm: affirm,
                usBankAccount: usBankAccount,
                cashApp: cashApp,
                revolutPay: revolutPay,
                swish: swish,
                amazonPay: amazonPay,
                alma: alma,
                sunbit: sunbit,
                billie: billie,
                satispay: satispay,
                crypto: crypto,
                multibanco: multibanco,
                mobilePay: mobilePay
            )
        }

        public static func == (lhs: PaymentMethodPreview, rhs: PaymentMethodPreview) -> Bool {
            return lhs.type == rhs.type &&
                   lhs.billingDetails == rhs.billingDetails &&
                   lhs.allowRedisplay == rhs.allowRedisplay &&
                   lhs.customerId == rhs.customerId &&
                   lhs.card == rhs.card &&
                   lhs.alipay == rhs.alipay &&
                   lhs.grabPay == rhs.grabPay &&
                   lhs.iDEAL == rhs.iDEAL &&
                   lhs.fpx == rhs.fpx &&
                   lhs.cardPresent == rhs.cardPresent &&
                   lhs.sepaDebit == rhs.sepaDebit &&
                   lhs.bacsDebit == rhs.bacsDebit &&
                   lhs.auBECSDebit == rhs.auBECSDebit &&
                   lhs.giropay == rhs.giropay &&
                   lhs.eps == rhs.eps &&
                   lhs.przelewy24 == rhs.przelewy24 &&
                   lhs.bancontact == rhs.bancontact &&
                   lhs.netBanking == rhs.netBanking &&
                   lhs.oxxo == rhs.oxxo &&
                   lhs.sofort == rhs.sofort &&
                   lhs.upi == rhs.upi &&
                   lhs.payPal == rhs.payPal &&
                   lhs.afterpayClearpay == rhs.afterpayClearpay &&
                   lhs.blik == rhs.blik &&
                   lhs.weChatPay == rhs.weChatPay &&
                   lhs.boleto == rhs.boleto &&
                   lhs.link == rhs.link &&
                   lhs.klarna == rhs.klarna &&
                   lhs.affirm == rhs.affirm &&
                   lhs.usBankAccount == rhs.usBankAccount &&
                   lhs.cashApp == rhs.cashApp &&
                   lhs.revolutPay == rhs.revolutPay &&
                   lhs.swish == rhs.swish &&
                   lhs.amazonPay == rhs.amazonPay &&
                   lhs.alma == rhs.alma &&
                   lhs.sunbit == rhs.sunbit &&
                   lhs.billie == rhs.billie &&
                   lhs.satispay == rhs.satispay &&
                   lhs.crypto == rhs.crypto &&
                   lhs.multibanco == rhs.multibanco &&
                   lhs.mobilePay == rhs.mobilePay
        }
    }
}
