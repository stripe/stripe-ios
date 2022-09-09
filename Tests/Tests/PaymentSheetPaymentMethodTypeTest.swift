//
//  PaymentSheetPaymentMethodTypeTest.swift
//  StripeiOS Tests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest
@_spi(STP) @testable import Stripe

class PaymentSheetPaymentMethodTypeTest: XCTestCase {

    func testInit() {
        XCTAssertEqual(PaymentSheet.PaymentMethodType(from: "card"), .card)
        XCTAssertEqual(PaymentSheet.PaymentMethodType(from: "us_bank_account"), .USBankAccount)
        XCTAssertEqual(PaymentSheet.PaymentMethodType(from: "link"), .link)
        XCTAssertEqual(PaymentSheet.PaymentMethodType(from: "mock_payment_method"), .dynamic("mock_payment_method"))
    }

    func testString() {
        XCTAssertEqual(PaymentSheet.PaymentMethodType.string(from: .card), "card")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.string(from: .USBankAccount), "us_bank_account")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.string(from: .link), "link")
        XCTAssertNil(PaymentSheet.PaymentMethodType.string(from: .linkInstantDebit))
        XCTAssertEqual(PaymentSheet.PaymentMethodType.string(from: .dynamic("mock_payment_method")), "mock_payment_method")
    }

    func testDisplayName() {
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("card").displayName, "Card")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.card.displayName, "Card")

        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("us_bank_account").displayName, "US Bank Account")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.USBankAccount.displayName, "US Bank Account")

        XCTAssertEqual(PaymentSheet.PaymentMethodType.link.displayName, "Link")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("link").displayName, "Link")

        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("alipay").displayName, "Alipay")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("ideal").displayName, "iDEAL")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("fpx").displayName, "FPX")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("sepa_debit").displayName, "SEPA Debit")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("au_becs_debit").displayName, "AU BECS Direct Debit")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("grabpay").displayName, "GrabPay")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("giropay").displayName, "giropay")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("eps").displayName, "EPS")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("p24").displayName, "Przelewy24")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("bancontact").displayName, "Bancontact")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("netbanking").displayName, "NetBanking")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("oxxo").displayName, "OXXO")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("sofort").displayName, "Sofort")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("upi").displayName, "UPI")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("paypal").displayName, "PayPal")
        if Locale.current.regionCode == "GB" {
            XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("afterpay_clearpay").displayName, "Clearpay")
        } else {
            XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("afterpay_clearpay").displayName, "Afterpay")
        }
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("blik").displayName, "BLIK")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("wechat_pay").displayName, "WeChat Pay")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("boleto").displayName, "Boleto")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("link").displayName, "Link")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("klarna").displayName, "Klarna")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("affirm").displayName, "Affirm")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("").displayName, "")
    }

    func testSTPPaymentMethodType() {
        XCTAssertEqual(PaymentSheet.PaymentMethodType.card.stpPaymentMethodType, .card)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("card").stpPaymentMethodType, .card)

        XCTAssertEqual(PaymentSheet.PaymentMethodType.USBankAccount.stpPaymentMethodType, .USBankAccount)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("us_bank_account").stpPaymentMethodType, .USBankAccount)

        XCTAssertEqual(PaymentSheet.PaymentMethodType.linkInstantDebit.stpPaymentMethodType, .linkInstantDebit)

        XCTAssertEqual(PaymentSheet.PaymentMethodType.link.stpPaymentMethodType, .link)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("link").stpPaymentMethodType, .link)

        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("alipay").stpPaymentMethodType, .alipay)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("ideal").stpPaymentMethodType, .iDEAL)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("fpx").stpPaymentMethodType, .FPX)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("sepa_debit").stpPaymentMethodType, .SEPADebit)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("au_becs_debit").stpPaymentMethodType, .AUBECSDebit)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("grabpay").stpPaymentMethodType, .grabPay)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("giropay").stpPaymentMethodType, .giropay)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("eps").stpPaymentMethodType, .EPS)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("p24").stpPaymentMethodType, .przelewy24)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("bancontact").stpPaymentMethodType, .bancontact)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("netbanking").stpPaymentMethodType, .netBanking)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("oxxo").stpPaymentMethodType, .OXXO)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("sofort").stpPaymentMethodType, .sofort)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("upi").stpPaymentMethodType, .UPI)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("paypal").stpPaymentMethodType, .payPal)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("afterpay_clearpay").stpPaymentMethodType, .afterpayClearpay)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("blik").stpPaymentMethodType, .blik)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("wechat_pay").stpPaymentMethodType, .weChatPay)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("boleto").stpPaymentMethodType, .boleto)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("klarna").stpPaymentMethodType, .klarna)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("affirm").stpPaymentMethodType, .affirm)
        XCTAssertNil(PaymentSheet.PaymentMethodType.dynamic("doesNotExist").stpPaymentMethodType)
    }

    func testConvertingNonDynamicTypes() {
        XCTAssertEqual(PaymentSheet.PaymentMethodType.card.stpPaymentMethodType,
                       PaymentSheet.PaymentMethodType.dynamic("card").stpPaymentMethodType)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.USBankAccount.stpPaymentMethodType,
                       PaymentSheet.PaymentMethodType.dynamic("us_bank_account").stpPaymentMethodType)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.link.stpPaymentMethodType,
                       PaymentSheet.PaymentMethodType.dynamic("link").stpPaymentMethodType)
    }

    func testPaymentIntentRecommendedPaymentMethodTypes() {
        let paymentIntent = constructPI(paymentMethodTypes: ["card", "us_bank_account", "klarna", "futurePaymentMethod"],
                                        orderedPaymentMethodTypes: ["card", "klarna", "us_bank_account", "futurePaymentMethod"])!
        let intent = Intent.paymentIntent(paymentIntent)
        let types = PaymentSheet.PaymentMethodType.recommendedPaymentMethodTypes(from: intent)

        XCTAssertEqual(types[0], .card)
        XCTAssertEqual(types[1], .dynamic("klarna"))
        XCTAssertEqual(types[2], .USBankAccount)
        XCTAssertEqual(types[3], .dynamic("futurePaymentMethod"))

    }

    func testPaymentIntentRecommendedPaymentMethodTypes_withoutOrderedPaymentMethodTypes() {
        let paymentIntent = constructPI(paymentMethodTypes: ["card", "us_bank_account", "klarna", "futurePaymentMethod"])!
        let intent = Intent.paymentIntent(paymentIntent)
        let types = PaymentSheet.PaymentMethodType.recommendedPaymentMethodTypes(from: intent)

        XCTAssertEqual(types[0], .card)
        XCTAssertEqual(types[1], .USBankAccount)
        XCTAssertEqual(types[2], .dynamic("klarna"))
        XCTAssertEqual(types[3], .dynamic("futurePaymentMethod"))
    }

    func testSetupIntentRecommendedPaymentMethodTypes() {
        let setupIntent = constructSI(paymentMethodTypes: ["card", "us_bank_account", "klarna", "futurePaymentMethod"])!
        let intent = Intent.setupIntent(setupIntent)
        let types = PaymentSheet.PaymentMethodType.recommendedPaymentMethodTypes(from: intent)

        XCTAssertEqual(types[0], .card)
        XCTAssertEqual(types[1], .USBankAccount)
        XCTAssertEqual(types[2], .dynamic("klarna"))
        XCTAssertEqual(types[3], .dynamic("futurePaymentMethod"))
    }

    func testSetupIntentRecommendedPaymentMethodTypes_withoutOrderedPaymentMethodTypes() {
        let setupIntent = constructSI(paymentMethodTypes: ["card", "us_bank_account", "klarna", "futurePaymentMethod"],
                                      orderedPaymentMethodTypes: ["card", "klarna", "us_bank_account", "futurePaymentMethod"])!
        let intent = Intent.setupIntent(setupIntent)
        let types = PaymentSheet.PaymentMethodType.recommendedPaymentMethodTypes(from: intent)

        XCTAssertEqual(types[0], .card)
        XCTAssertEqual(types[1], .dynamic("klarna"))
        XCTAssertEqual(types[2], .USBankAccount)
        XCTAssertEqual(types[3], .dynamic("futurePaymentMethod"))
    }

    func testSupportsAdding() {
        let paymentIntent = constructPI(paymentMethodTypes: ["luxe_bucks"])!
        let intent = Intent.paymentIntent(paymentIntent)
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "http://return-to-url"

        XCTAssertFalse(PaymentSheet.PaymentMethodType.supportsAdding(paymentMethod: .dynamic("luxe_bucks"),
                                                                   configuration: configuration,
                                                                   intent: intent))
    }
    func testSupportsSaveAndReuse() {
        let setupIntent = constructSI(paymentMethodTypes: ["luxe_bucks"])!
        let intent = Intent.setupIntent(setupIntent)
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "http://return-to-url"

        XCTAssertFalse(PaymentSheet.PaymentMethodType.supportsSaveAndReuse(paymentMethod: .dynamic("luxe_bucks"),
                                                                          configuration: configuration,
                                                                          intent: intent))
    }

    func testSupport() {
        let paymentIntent = constructPI(paymentMethodTypes: ["luxe_bucks"])!
        let intent = Intent.paymentIntent(paymentIntent)
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "http://return-to-url"

        XCTAssertTrue(PaymentSheet.PaymentMethodType.supports(requirements: [.returnURL, .notSettingUp],
                                                             configuration: configuration,
                                                             intent: intent))
    }
    func testArrayToString() {
        let paymentMethodTypes: [PaymentSheet.PaymentMethodType] = [.card, .dynamic("llammaPay")]

        let strList = paymentMethodTypes.stringList()

        XCTAssertEqual(strList, "[\"card\",\"llammaPay\"]")
    }
    func testArrayToString_empty() {
        let paymentMethodTypes: [PaymentSheet.PaymentMethodType] = []

        let strList = paymentMethodTypes.stringList()

        XCTAssertEqual(strList, "[]")
    }
    func testSymmetricDifference_same() {
        let paymentMethodTypes1: [PaymentSheet.PaymentMethodType] = [.card, .dynamic("llammaPay")]
        let paymentMethodTypes2: [PaymentSheet.PaymentMethodType] = [.card, .dynamic("llammaPay")]

        let result = paymentMethodTypes1.symmetricDifference(paymentMethodTypes2)

        XCTAssertEqual(result, [])
    }
    func testSymmetricDifference_difference1() {
        let paymentMethodTypes1: [PaymentSheet.PaymentMethodType] = [.card, .dynamic("llammaPay"), .dynamic("wechatpay")]
        let paymentMethodTypes2: [PaymentSheet.PaymentMethodType] = [.card, .dynamic("llammaPay")]

        let result = paymentMethodTypes1.symmetricDifference(paymentMethodTypes2)

        XCTAssertEqual(result, [.dynamic("wechatpay")])
    }
    func testSymmetricDifference_difference2() {
        let paymentMethodTypes1: [PaymentSheet.PaymentMethodType] = [.card, .dynamic("llammaPay")]
        let paymentMethodTypes2: [PaymentSheet.PaymentMethodType] = [.card, .dynamic("llammaPay"), .dynamic("wechatpay")]

        let result = paymentMethodTypes1.symmetricDifference(paymentMethodTypes2)

        XCTAssertEqual(result, [.dynamic("wechatpay")])
    }
    func testSymmetricDifference_differenceInBoth() {
        let paymentMethodTypes1: [PaymentSheet.PaymentMethodType] = [.card, .dynamic("llammaPay"), .dynamic("wechatpay")]
        let paymentMethodTypes2: [PaymentSheet.PaymentMethodType] = [.card, .dynamic("llammaPay"), .dynamic("affirm")]

        let result = paymentMethodTypes1.symmetricDifference(paymentMethodTypes2)

        XCTAssertTrue(result == [.dynamic("wechatpay"), .dynamic("affirm")] ||
                      result == [.dynamic("affirm"), .dynamic("wechatpay")])
    }


    private func constructPI(paymentMethodTypes: [String],
                             orderedPaymentMethodTypes: [String]? = nil) -> STPPaymentIntent? {
        var apiResponse: [AnyHashable: Any] = [
            "id": "123",
            "client_secret": "sec",
            "amount": 10,
            "currency": "usd",
            "status": "requires_payment_method",
            "livemode": false,
            "created": 1652736692.0,
            "payment_method_types": paymentMethodTypes,
        ]
        if let orderedPaymentMethodTypes = orderedPaymentMethodTypes {
             apiResponse["ordered_payment_method_types"] = orderedPaymentMethodTypes
        }
        guard let stpPaymentIntent = STPPaymentIntent.decodeSTPPaymentIntentObject(fromAPIResponse: apiResponse) else {
            XCTFail("Failed to decode")
            return nil
        }
        return stpPaymentIntent
    }
    private func constructSI(paymentMethodTypes: [String],
                             orderedPaymentMethodTypes: [String]? = nil) -> STPSetupIntent? {
        var apiResponse: [AnyHashable: Any] = [
            "id": "123",
            "client_secret": "sec",
            "status": "requires_payment_method",
            "created": 1652736692.0,
            "payment_method_types": paymentMethodTypes,
            "livemode": false
        ]
        if let orderedPaymentMethodTypes = orderedPaymentMethodTypes {
             apiResponse["ordered_payment_method_types"] = orderedPaymentMethodTypes
        }
        guard let stpSetupIntent = STPSetupIntent.decodeSTPSetupIntentObject(fromAPIResponse: apiResponse) else {
            XCTFail("Failed to decode")
            return nil
        }
        return stpSetupIntent
    }

}
