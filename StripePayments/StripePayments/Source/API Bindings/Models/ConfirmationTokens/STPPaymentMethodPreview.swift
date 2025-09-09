//
//  STPPaymentMethodPreview.swift
//  StripePayments
//

import Foundation

/// Preview of payment method details captured by the ConfirmationToken.
@_spi(ConfirmationTokensPublicPreview) public class STPPaymentMethodPreview: NSObject, STPAPIResponseDecodable {

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

    /// :nodoc:
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    internal init(
        type: STPPaymentMethodType,
        billingDetails: STPPaymentMethodBillingDetails?,
        allowRedisplay: STPPaymentMethodAllowRedisplay,
        customerId: String?,
        card: STPPaymentMethodCard?,
        alipay: STPPaymentMethodAlipay?,
        grabPay: STPPaymentMethodGrabPay?,
        iDEAL: STPPaymentMethodiDEAL?,
        fpx: STPPaymentMethodFPX?,
        cardPresent: STPPaymentMethodCardPresent?,
        sepaDebit: STPPaymentMethodSEPADebit?,
        bacsDebit: STPPaymentMethodBacsDebit?,
        auBECSDebit: STPPaymentMethodAUBECSDebit?,
        giropay: STPPaymentMethodGiropay?,
        eps: STPPaymentMethodEPS?,
        przelewy24: STPPaymentMethodPrzelewy24?,
        bancontact: STPPaymentMethodBancontact?,
        netBanking: STPPaymentMethodNetBanking?,
        oxxo: STPPaymentMethodOXXO?,
        sofort: STPPaymentMethodSofort?,
        upi: STPPaymentMethodUPI?,
        payPal: STPPaymentMethodPayPal?,
        afterpayClearpay: STPPaymentMethodAfterpayClearpay?,
        blik: STPPaymentMethodBLIK?,
        weChatPay: STPPaymentMethodWeChatPay?,
        boleto: STPPaymentMethodBoleto?,
        link: STPPaymentMethodLink?,
        klarna: STPPaymentMethodKlarna?,
        affirm: STPPaymentMethodAffirm?,
        usBankAccount: STPPaymentMethodUSBankAccount?,
        cashApp: STPPaymentMethodCashApp?,
        revolutPay: STPPaymentMethodRevolutPay?,
        swish: STPPaymentMethodSwish?,
        amazonPay: STPPaymentMethodAmazonPay?,
        alma: STPPaymentMethodAlma?,
        sunbit: STPPaymentMethodSunbit?,
        billie: STPPaymentMethodBillie?,
        satispay: STPPaymentMethodSatispay?,
        crypto: STPPaymentMethodCrypto?,
        multibanco: STPPaymentMethodMultibanco?,
        mobilePay: STPPaymentMethodMobilePay?,
        allResponseFields: [AnyHashable: Any]
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
        self.allResponseFields = allResponseFields
        super.init()
    }

    @objc
    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = response.stp_dictionaryByRemovingNulls()

        guard let typeString = dict.stp_string(forKey: "type") else {
            return nil
        }

        let type = STPPaymentMethod.type(from: typeString)
        let allowRedisplay = STPPaymentMethod.allowRedisplay(from: dict.stp_string(forKey: "allow_redisplay") ?? "")
        let customerId = dict.stp_string(forKey: "customer")

        // Parse billing_details
        let billingDetails = STPPaymentMethodBillingDetails.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "billing_details")
        )

        // Parse type-specific payment method details using the same pattern as STPPaymentMethod
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

        return STPPaymentMethodPreview(
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
            mobilePay: mobilePay,
            allResponseFields: response
        ) as? Self
    }
}
