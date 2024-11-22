//
//  STPPaymentMethod.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

/// PaymentMethod objects represent your customer's payment instruments. They can be used with PaymentIntents to collect payments.
/// - seealso: https://stripe.com/docs/api/payment_methods
public class STPPaymentMethod: NSObject, STPAPIResponseDecodable {
    /// Unique identifier for the object.
    @objc private(set) public var stripeId: String
    /// Time at which the object was created. Measured in seconds since the Unix epoch.
    @objc private(set) public var created: Date?
    /// `YES` if the object exists in live mode or the value `NO` if the object exists in test mode.
    @objc private(set) public var liveMode = false
    /// The type of the PaymentMethod.  The corresponding, similarly named property contains additional information specific to the PaymentMethod type.
    /// e.g. if the type is `STPPaymentMethodTypeCard`, the `card` property is also populated.
    @objc private(set) public var type: STPPaymentMethodType = .unknown
    /// Billing information associated with the PaymentMethod that may be used or required by particular types of payment methods.
    @objc private(set) public var billingDetails: STPPaymentMethodBillingDetails?
    /// If this is an Alipay PaymentMethod (ie `self.type == STPPaymentMethodTypeAlipay`), this contains additional detailsl
    @objc private(set) public var alipay: STPPaymentMethodAlipay?
    /// If this is a GrabPay PaymentMethod (ie `self.type == STPPaymentMethodTypeGrabPay`), this contains additional details.
    @objc private(set) public var grabPay: STPPaymentMethodGrabPay?
    /// If this is a card PaymentMethod (ie `self.type == STPPaymentMethodTypeCard`), this contains additional details.
    @objc private(set) public var card: STPPaymentMethodCard?
    /// If this is a iDEAL PaymentMethod (ie `self.type == STPPaymentMethodTypeiDEAL`), this contains additional details.
    @objc private(set) public var iDEAL: STPPaymentMethodiDEAL?
    /// If this is an FPX PaymentMethod (ie `self.type == STPPaymentMethodTypeFPX`), this contains additional details.
    @objc private(set) public var fpx: STPPaymentMethodFPX?
    /// If this is a card present PaymentMethod (ie `self.type == STPPaymentMethodTypeCardPresent`), this contains additional details.
    @objc private(set) public var cardPresent: STPPaymentMethodCardPresent?
    /// If this is a SEPA Debit PaymentMethod (ie `self.type == STPPaymentMethodTypeSEPADebit`), this contains additional details.
    @objc private(set) public var sepaDebit: STPPaymentMethodSEPADebit?
    /// If this is a Bacs Debit PaymentMethod (ie `self.type == STPPaymentMethodTypeBacsDebit`), this contains additional details.
    @objc private(set) public var bacsDebit: STPPaymentMethodBacsDebit?
    /// If this is an AU BECS Debit PaymentMethod (i.e. `self.type == STPPaymentMethodTypeAUBECSDebit`), this contains additional details.
    @objc private(set) public var auBECSDebit: STPPaymentMethodAUBECSDebit?
    /// If this is a giropay PaymentMethod (i.e. `self.type == STPPaymentMethodTypeGiropay`), this contains additional details.
    @objc private(set) public var giropay: STPPaymentMethodGiropay?
    /// If this is an EPS PaymentMethod (i.e. `self.type == STPPaymentMethodTypeEPS`), this contains additional details.
    @objc private(set) public var eps: STPPaymentMethodEPS?
    /// If this is a Przelewy24 PaymentMethod (i.e. `self.type == STPPaymentMethodTypePrzelewy24`), this contains additional details.
    @objc private(set) public var przelewy24: STPPaymentMethodPrzelewy24?
    /// If this is a Bancontact PaymentMethod (i.e. `self.type == STPPaymentMethodTypeBancontact`), this contains additional details.
    @objc private(set) public var bancontact: STPPaymentMethodBancontact?
    /// If this is a NetBanking PaymentMethod (i.e. `self.type == STPPaymentMethodTypeNetBanking`), this contains additional details.
    @objc private(set) public var netBanking: STPPaymentMethodNetBanking?
    /// If this is an OXXO PaymentMethod (i.e. `self.type == STPPaymentMethodTypeOXXO`), this contains additional details.
    @objc private(set) public var oxxo: STPPaymentMethodOXXO?
    /// If this is a Sofort PaymentMethod (i.e. `self.type == STPPaymentMethodTypeSofort`), this contains additional details.
    @objc private(set) public var sofort: STPPaymentMethodSofort?
    /// If this is a UPI PaymentMethod (i.e. `self.type == STPPaymentMethodTypeUPI`), this contains additional details. :nodoc:
    @objc private(set) public var upi: STPPaymentMethodUPI?
    /// If this is a PayPal PaymentMethod (i.e. `self.type == STPPaymentMethodTypePayPal`), this contains additional details. :nodoc:
    @objc private(set) public var payPal: STPPaymentMethodPayPal?
    /// If this is an AfterpayClearpay PaymentMethod (i.e. `self.type == STPPaymentMethodTypeAfterpayClearpay`), this contains additional details. :nodoc:
    @objc private(set) public var afterpayClearpay: STPPaymentMethodAfterpayClearpay?
    /// If this is a BLIK PaymentMethod (i.e. `self.type == STPPaymentMethodTypeBLIK`), this contains additional details. :nodoc:
    @objc private(set) public var blik: STPPaymentMethodBLIK?
    /// If this is a WeChat Pay PaymentMethod (i.e. `self.type == STPPaymentMethodTypeWeChatPay`), this contains additional details.
    @objc private(set) var weChatPay: STPPaymentMethodWeChatPay?
    /// If this is an Boleto PaymentMethod (i.e. `self.type == STPPaymentMethodTypeBoleto`), this contains additional details.
    @objc private(set) public var boleto: STPPaymentMethodBoleto?
    /// If this is a Link PaymentMethod (i.e. `self.type == STPPaymentMethodTypeLink`), this contains additional details.
    @objc private(set) public var link: STPPaymentMethodLink?
    /// If this is an Klarna PaymentMethod (i.e. `self.type == STPPaymentMethodTypeKlarna`), this contains additional details.
    @objc private(set) public var klarna: STPPaymentMethodKlarna?
    /// If this is an Affirm PaymentMethod (i.e. `self.type == STPPaymentMethodTypeAffirm`), this contains additional details.
    @objc private(set) public var affirm: STPPaymentMethodAffirm?
    /// If this is a US Bank Account PaymentMethod (i.e. `self.type == STPPaymentMethodTypeUSBankAccount`), this contains additional details.
    @objc private(set) public var usBankAccount: STPPaymentMethodUSBankAccount?
    /// If this is an Cash App PaymentMethod (i.e. `self.type == STPPaymentMethodTypeCashApp`), this contains additional details.
    @objc private(set) public var cashApp: STPPaymentMethodCashApp?
    /// If this is an RevolutPay PaymentMethod (i.e. `self.type == STPPaymentMethodTypeRevolutPay`), this contains additional details.
    @objc private(set) public var revolutPay: STPPaymentMethodRevolutPay?
    /// If this is a Swish PaymentMethod (i.e. `self.type == STPPaymentMethodTypeSwish`), this contains additional details.
    @objc private(set) public var swish: STPPaymentMethodSwish?
    /// If this is a Amazon Pay PaymentMethod (i.e. `self.type == STPPaymentMethodTypeAmazonPay`), this contains additional details.
    @objc private(set) public var amazonPay: STPPaymentMethodAmazonPay?
    /// If this is a Alma PaymentMethod (i.e. `self.type == STPPaymentMethodTypeAlma`), this contains additional details.
    @objc private(set) public var alma: STPPaymentMethodAlma?
    /// If this is a Sunbit PaymentMethod (i.e. `self.type == STPPaymentMethodTypeSunibt`), this contains additional details.
    @objc private(set) public var sunbit: STPPaymentMethodSunbit?
    /// If this is a Billie PaymentMethod (i.e. `self.type == STPPaymentMethodTypeBillie`), this contains additional details.
    @objc private(set) public var billie: STPPaymentMethodBillie?
    /// If this is a Satispay PaymentMethod (i.e. `self.type == STPPaymentMethodTypeSatispay`), this contains additional details.
    @objc private(set) public var satispay: STPPaymentMethodSatispay?
    /// If this is a Crypto PaymentMethod (i.e. `self.type == STPPaymentMethodTypeCrypto`), this contains additional details.
    @objc private(set) public var crypto: STPPaymentMethodCrypto?
    /// If this is a Multibanco PaymentMethod (i.e. `self.type == STPPaymentMethodTypeMultibanco`), this contains additional details.
    @objc private(set) public var multibanco: STPPaymentMethodMultibanco?
    /// If this is a MobilePay PaymentMethod (i.e. `self.type == STPPaymentMethodTypeMobilePay`), this contains additional details.
    @objc private(set) public var mobilePay: STPPaymentMethodMobilePay?

    /// This field indicates whether this payment method can be shown again to its customer in a checkout flow
    @objc private(set) public var allowRedisplay: STPPaymentMethodAllowRedisplay

    /// The ID of the Customer to which this PaymentMethod is saved. Nil when the PaymentMethod has not been saved to a Customer.
    @objc private(set) public var customerId: String?
    // MARK: - Deprecated

    /// Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    /// @deprecated Metadata is no longer returned to clients using publishable keys. Retrieve them on your server using yoursecret key instead.
    /// - seealso: https://stripe.com/docs/api#metadata
    @available(
        *,
        deprecated,
        message:
            "Metadata is no longer returned to clients using publishable keys. Retrieve them on your server using your secret key instead."
    )
    @objc private(set) public var metadata: [String: String]?

    /// :nodoc:
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethod.self), self),
            // Identifier
            "stripeId = \(stripeId)",
            // STPPaymentMethod details (alphabetical)
            "alipay = \(String(describing: alipay))",
            "auBECSDebit = \(String(describing: auBECSDebit))",
            "bacsDebit = \(String(describing: bacsDebit))",
            "bancontact = \(String(describing: bancontact))",
            "billingDetails = \(String(describing: billingDetails))",
            "card = \(String(describing: card))",
            "cardPresent = \(String(describing: cardPresent))",
            "created = \(String(describing: created))",
            "customerId = \(customerId ?? "")",
            "ideal = \(String(describing: iDEAL))",
            "eps = \(String(describing: eps))",
            "fpx = \(String(describing: fpx))",
            "giropay = \(String(describing: giropay))",
            "netBanking = \(String(describing: netBanking))",
            "oxxo = \(String(describing: oxxo))",
            "grabPay = \(String(describing: grabPay))",
            "payPal = \(String(describing: payPal))",
            "przelewy24 = \(String(describing: przelewy24))",
            "sepaDebit = \(String(describing: sepaDebit))",
            "sofort = \(String(describing: sofort))",
            "upi = \(String(describing: upi))",
            "afterpay_clearpay = \(String(describing: afterpayClearpay))",
            "blik = \(String(describing: blik))",
            "weChatPay = \(String(describing: weChatPay))",
            "boleto = \(String(describing: boleto))",
            "link = \(String(describing: link))",
            "klarna = \(String(describing: klarna))",
            "affirm = \(String(describing: affirm))",
            "usBankAccount = \(String(describing: usBankAccount))",
            "cashapp = \(String(describing: cashApp))",
            "revolutPay = \(String(describing: revolutPay))",
            "swish = \(String(describing: swish))",
            "amazon_pay = \(String(describing: amazonPay))",
            "alma = \(String(describing: alma))",
            "sunbit = \(String(describing: sunbit))",
            "billie = \(String(describing: billie))",
            "satispay = \(String(describing: satispay))",
            "crypto = \(String(describing: crypto))",
            "multibanco = \(String(describing: multibanco))",
            "mobilePay = \(String(describing: mobilePay))",
            "liveMode = \(liveMode ? "YES" : "NO")",
            "allowRedisplay = \(allResponseFields["allow_redisplay"] as? String ?? "")",
            "type = \(allResponseFields["type"] as? String ?? "")",
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPPaymentMethodType

    @_spi(STP) public class func string(from type: STPPaymentMethodType) -> String? {
        guard type != .unknown else {
            return nil
        }
        return type.identifier
    }

    @_spi(STP) public class func type(from string: String) -> STPPaymentMethodType {
        let key = string.lowercased()
        return STPPaymentMethodType.allCases.first(where: { type in
            type.identifier == key
        }) ?? .unknown
    }

    @_spi(STP) public class func allowRedisplay(from string: String) -> STPPaymentMethodAllowRedisplay {
        let key = string.lowercased()
        return STPPaymentMethodAllowRedisplay.allCases.first(where: { type in
            type.stringValue == key
        }) ?? .unspecified
    }

    class func types(from strings: [String]) -> [NSNumber] {
        var types: [AnyHashable] = []
        for string in strings {
            types.append(NSNumber(value: self.type(from: string).rawValue))
        }
        return types as? [NSNumber] ?? []
    }

    class func paymentMethodTypes(from strings: [String]) -> [STPPaymentMethodType] {
        var types: [STPPaymentMethodType] = []
        for string in strings {
            types.append(self.type(from: string))
        }
        return types
    }

    // MARK: - STPAPIResponseDecodable
    /// :nodoc:
    @objc @_spi(STP) public required init(
        stripeId: String,
        type: STPPaymentMethodType,
        allowRedisplay: STPPaymentMethodAllowRedisplay = .unspecified
    ) {
        self.stripeId = stripeId
        self.type = type
        self.allowRedisplay = allowRedisplay
        super.init()
    }

    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = response.stp_dictionaryByRemovingNulls()

        // Required fields
        guard let stripeId = dict.stp_string(forKey: "id") else {
            return nil
        }

        let paymentMethod = self.init(stripeId: stripeId,
                                      type: self.type(from: dict.stp_string(forKey: "type") ?? ""),
                                      allowRedisplay: self.allowRedisplay(from: dict.stp_string(forKey: "allow_redisplay") ?? ""))
        paymentMethod.allResponseFields = response
        paymentMethod.stripeId = stripeId
        paymentMethod.created = dict.stp_date(forKey: "created")
        paymentMethod.liveMode = dict.stp_bool(forKey: "livemode", or: false)
        paymentMethod.billingDetails = STPPaymentMethodBillingDetails.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "billing_details")
        )
        paymentMethod.card = STPPaymentMethodCard.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "card")
        )
        paymentMethod.iDEAL = STPPaymentMethodiDEAL.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "ideal")
        )
        if let stp = dict.stp_dictionary(forKey: "fpx") {
            paymentMethod.fpx = STPPaymentMethodFPX.decodedObject(fromAPIResponse: stp)
        }
        if let stp = dict.stp_dictionary(forKey: "card_present") {
            paymentMethod.cardPresent = STPPaymentMethodCardPresent.decodedObject(
                fromAPIResponse: stp
            )
        }
        paymentMethod.sepaDebit = STPPaymentMethodSEPADebit.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "sepa_debit")
        )
        paymentMethod.bacsDebit = STPPaymentMethodBacsDebit.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "bacs_debit")
        )
        paymentMethod.auBECSDebit = STPPaymentMethodAUBECSDebit.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "au_becs_debit")
        )
        paymentMethod.giropay = STPPaymentMethodGiropay.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "giropay")
        )
        paymentMethod.eps = STPPaymentMethodEPS.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "eps")
        )
        paymentMethod.przelewy24 = STPPaymentMethodPrzelewy24.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "p24")
        )
        paymentMethod.bancontact = STPPaymentMethodBancontact.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "bancontact")
        )
        paymentMethod.netBanking = STPPaymentMethodNetBanking.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "netbanking")
        )
        paymentMethod.oxxo = STPPaymentMethodOXXO.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "oxxo")
        )
        paymentMethod.sofort = STPPaymentMethodSofort.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "sofort")
        )
        paymentMethod.upi = STPPaymentMethodUPI.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "upi")
        )
        paymentMethod.customerId = dict.stp_string(forKey: "customer")
        paymentMethod.alipay = STPPaymentMethodAlipay.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "alipay")
        )
        paymentMethod.grabPay = STPPaymentMethodGrabPay.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "grabpay")
        )
        paymentMethod.payPal = STPPaymentMethodPayPal.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "paypal")
        )
        paymentMethod.afterpayClearpay = STPPaymentMethodAfterpayClearpay.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "afterpay_clearpay")
        )
        paymentMethod.blik = STPPaymentMethodBLIK.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "blik")
        )
        paymentMethod.weChatPay = STPPaymentMethodWeChatPay.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "wechat_pay")
        )
        paymentMethod.boleto = STPPaymentMethodBoleto.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "boleto")
        )
        paymentMethod.link = STPPaymentMethodLink.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "link")
        )
        paymentMethod.klarna = STPPaymentMethodKlarna.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "klarna")
        )
        paymentMethod.affirm = STPPaymentMethodAffirm.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "affirm")
        )
        paymentMethod.usBankAccount = STPPaymentMethodUSBankAccount.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "us_bank_account")
        )
        paymentMethod.cashApp = STPPaymentMethodCashApp.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "cashapp")
        )
        paymentMethod.revolutPay = STPPaymentMethodRevolutPay.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "revolut_pay")
        )
        paymentMethod.swish = STPPaymentMethodSwish.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "swish")
        )
        paymentMethod.amazonPay = STPPaymentMethodAmazonPay.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "amazon_pay")
        )
        paymentMethod.alma = STPPaymentMethodAlma.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "alma")
        )
        paymentMethod.sunbit = STPPaymentMethodSunbit.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "sunbit")
        )
        paymentMethod.billie = STPPaymentMethodBillie.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "billie")
        )
        paymentMethod.satispay = STPPaymentMethodSatispay.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "satispay")
        )
        paymentMethod.crypto = STPPaymentMethodCrypto.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "crypto")
        )
        paymentMethod.multibanco = STPPaymentMethodMultibanco.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "multibanco")
        )
        paymentMethod.mobilePay = STPPaymentMethodMobilePay.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "mobilepay")
        )

        return paymentMethod
    }
}
