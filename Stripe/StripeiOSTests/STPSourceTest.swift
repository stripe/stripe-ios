//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPSourceTest.swift
//  Stripe
//
//  Created by Ben Guo on 1/24/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import XCTest

class STPSource {
    private class func flow(from string: String?) -> STPSourceFlow {
    }

    private class func status(from string: String?) -> STPSourceStatus {
    }

    private class func string(from status: STPSourceStatus) -> String? {
    }

    private class func usage(from string: String?) -> STPSourceUsage {
    }
}

class STPSourceTest: XCTestCase {
    // MARK: - STPSourceType Tests

    func testTypeFromString() {
        XCTAssertEqual(STPSource.type(fromString: "bancontact"), Int(STPSourceTypeBancontact))
        XCTAssertEqual(STPSource.type(fromString: "BANCONTACT"), Int(STPSourceTypeBancontact))

        XCTAssertEqual(STPSource.type(fromString: "card"), Int(STPSourceTypeCard))
        XCTAssertEqual(STPSource.type(fromString: "CARD"), Int(STPSourceTypeCard))

        XCTAssertEqual(STPSource.type(fromString: "giropay"), Int(STPSourceTypeGiropay))
        XCTAssertEqual(STPSource.type(fromString: "GIROPAY"), Int(STPSourceTypeGiropay))

        XCTAssertEqual(STPSource.type(fromString: "ideal"), Int(STPSourceTypeiDEAL))
        XCTAssertEqual(STPSource.type(fromString: "IDEAL"), Int(STPSourceTypeiDEAL))

        XCTAssertEqual(STPSource.type(fromString: "sepa_debit"), Int(STPSourceTypeSEPADebit))
        XCTAssertEqual(STPSource.type(fromString: "SEPA_DEBIT"), Int(STPSourceTypeSEPADebit))

        XCTAssertEqual(STPSource.type(fromString: "sofort"), Int(STPSourceTypeSofort))
        XCTAssertEqual(STPSource.type(fromString: "Sofort"), Int(STPSourceTypeSofort))

        XCTAssertEqual(STPSource.type(fromString: "three_d_secure"), Int(STPSourceTypeThreeDSecure))
        XCTAssertEqual(STPSource.type(fromString: "THREE_D_SECURE"), Int(STPSourceTypeThreeDSecure))

        XCTAssertEqual(STPSource.type(fromString: "alipay"), Int(STPSourceTypeAlipay))
        XCTAssertEqual(STPSource.type(fromString: "ALIPAY"), Int(STPSourceTypeAlipay))

        XCTAssertEqual(STPSource.type(fromString: "p24"), Int(STPSourceTypeP24))
        XCTAssertEqual(STPSource.type(fromString: "P24"), Int(STPSourceTypeP24))

        XCTAssertEqual(STPSource.type(fromString: "eps"), Int(STPSourceTypeEPS))
        XCTAssertEqual(STPSource.type(fromString: "EPS"), Int(STPSourceTypeEPS))

        XCTAssertEqual(STPSource.type(fromString: "multibanco"), Int(STPSourceTypeMultibanco))
        XCTAssertEqual(STPSource.type(fromString: "MULTIBANCO"), Int(STPSourceTypeMultibanco))

        XCTAssertEqual(STPSource.type(fromString: "unknown"), Int(STPSourceTypeUnknown))
        XCTAssertEqual(STPSource.type(fromString: "UNKNOWN"), Int(STPSourceTypeUnknown))

        XCTAssertEqual(STPSource.type(fromString: "garbage"), Int(STPSourceTypeUnknown))
        XCTAssertEqual(STPSource.type(fromString: "GARBAGE"), Int(STPSourceTypeUnknown))
    }

    func testStringFromType() {
        let values = [
            NSNumber(value: STPSourceTypeBancontact),
            NSNumber(value: STPSourceTypeCard),
            NSNumber(value: STPSourceTypeGiropay),
            NSNumber(value: STPSourceTypeiDEAL),
            NSNumber(value: STPSourceTypeSEPADebit),
            NSNumber(value: STPSourceTypeSofort),
            NSNumber(value: STPSourceTypeThreeDSecure),
            NSNumber(value: STPSourceTypeAlipay),
            NSNumber(value: STPSourceTypeP24),
            NSNumber(value: STPSourceTypeEPS),
            NSNumber(value: STPSourceTypeMultibanco),
            NSNumber(value: STPSourceTypeUnknown),
        ]

        for typeNumber in values {
            let type = typeNumber.intValue as? STPSourceType
            let string = STPSource.string(from: type)

            switch type {
            case STPSourceTypeBancontact:
                XCTAssertEqual(string, "bancontact")
            case STPSourceTypeCard:
                XCTAssertEqual(string, "card")
            case STPSourceTypeGiropay:
                XCTAssertEqual(string, "giropay")
            case STPSourceTypeiDEAL:
                XCTAssertEqual(string, "ideal")
            case STPSourceTypeSEPADebit:
                XCTAssertEqual(string, "sepa_debit")
            case STPSourceTypeSofort:
                XCTAssertEqual(string, "sofort")
            case STPSourceTypeThreeDSecure:
                XCTAssertEqual(string, "three_d_secure")
            case STPSourceTypeAlipay:
                XCTAssertEqual(string, "alipay")
            case STPSourceTypeP24:
                XCTAssertEqual(string, "p24")
            case STPSourceTypeEPS:
                XCTAssertEqual(string, "eps")
            case STPSourceTypeMultibanco:
                XCTAssertEqual(string, "multibanco")
            case STPSourceTypeWeChatPay:
                XCTAssertEqual(string, "wechat")
            case STPSourceTypeKlarna:
                XCTAssertEqual(string, "klarna")
            case STPSourceTypeUnknown:
                XCTAssertNil(string)
                break
            default:
                break
            }
        }
    }

    // MARK: - STPSourceFlow Tests

    func testFlowFromString() {
        XCTAssertEqual(Int(STPSource.flow(from: "redirect")), Int(STPSourceFlowRedirect))
        XCTAssertEqual(Int(STPSource.flow(from: "REDIRECT")), Int(STPSourceFlowRedirect))

        XCTAssertEqual(Int(STPSource.flow(from: "receiver")), Int(STPSourceFlowReceiver))
        XCTAssertEqual(Int(STPSource.flow(from: "RECEIVER")), Int(STPSourceFlowReceiver))

        XCTAssertEqual(Int(STPSource.flow(from: "code_verification")), Int(STPSourceFlowCodeVerification))
        XCTAssertEqual(Int(STPSource.flow(from: "CODE_VERIFICATION")), Int(STPSourceFlowCodeVerification))

        XCTAssertEqual(Int(STPSource.flow(from: "none")), Int(STPSourceFlowNone))
        XCTAssertEqual(Int(STPSource.flow(from: "NONE")), Int(STPSourceFlowNone))

        XCTAssertEqual(Int(STPSource.flow(from: "garbage")), Int(STPSourceFlowUnknown))
        XCTAssertEqual(Int(STPSource.flow(from: "GARBAGE")), Int(STPSourceFlowUnknown))
    }

    func testStringFromFlow() {
        let values = [
            NSNumber(value: STPSourceFlowRedirect),
            NSNumber(value: STPSourceFlowReceiver),
            NSNumber(value: STPSourceFlowCodeVerification),
            NSNumber(value: STPSourceFlowNone),
            NSNumber(value: STPSourceFlowUnknown),
        ]

        for flowNumber in values {
            let flow = flowNumber.intValue as? STPSourceFlow
            let string = STPSource.string(from: flow)

            switch flow {
            case STPSourceFlowRedirect:
                XCTAssertEqual(string, "redirect")
            case STPSourceFlowReceiver:
                XCTAssertEqual(string, "receiver")
            case STPSourceFlowCodeVerification:
                XCTAssertEqual(string, "code_verification")
            case STPSourceFlowNone:
                XCTAssertEqual(string, "none")
            case STPSourceFlowUnknown:
                XCTAssertNil(string)
                break
            default:
                break
            }
        }
    }

    // MARK: - STPSourceStatus Tests

    func testStatusFromString() {
        XCTAssertEqual(Int(STPSource.status(from: "pending")), Int(STPSourceStatusPending))
        XCTAssertEqual(Int(STPSource.status(from: "PENDING")), Int(STPSourceStatusPending))

        XCTAssertEqual(Int(STPSource.status(from: "chargeable")), Int(STPSourceStatusChargeable))
        XCTAssertEqual(Int(STPSource.status(from: "CHARGEABLE")), Int(STPSourceStatusChargeable))

        XCTAssertEqual(Int(STPSource.status(from: "consumed")), Int(STPSourceStatusConsumed))
        XCTAssertEqual(Int(STPSource.status(from: "CONSUMED")), Int(STPSourceStatusConsumed))

        XCTAssertEqual(Int(STPSource.status(from: "canceled")), Int(STPSourceStatusCanceled))
        XCTAssertEqual(Int(STPSource.status(from: "CANCELED")), Int(STPSourceStatusCanceled))

        XCTAssertEqual(Int(STPSource.status(from: "failed")), Int(STPSourceStatusFailed))
        XCTAssertEqual(Int(STPSource.status(from: "FAILED")), Int(STPSourceStatusFailed))

        XCTAssertEqual(Int(STPSource.status(from: "garbage")), Int(STPSourceStatusUnknown))
        XCTAssertEqual(Int(STPSource.status(from: "GARBAGE")), Int(STPSourceStatusUnknown))
    }

    func testStringFromStatus() {
        let values = [
            NSNumber(value: STPSourceStatusPending),
            NSNumber(value: STPSourceStatusChargeable),
            NSNumber(value: STPSourceStatusConsumed),
            NSNumber(value: STPSourceStatusCanceled),
            NSNumber(value: STPSourceStatusFailed),
            NSNumber(value: STPSourceStatusUnknown),
        ]

        for statusNumber in values {
            let status = statusNumber.intValue as? STPSourceStatus
            var string: String?
            if let status {
                string = STPSource.string(from: status)
            }

            switch status {
            case STPSourceStatusPending:
                XCTAssertEqual(string, "pending")
            case STPSourceStatusChargeable:
                XCTAssertEqual(string, "chargeable")
            case STPSourceStatusConsumed:
                XCTAssertEqual(string, "consumed")
            case STPSourceStatusCanceled:
                XCTAssertEqual(string, "canceled")
            case STPSourceStatusFailed:
                XCTAssertEqual(string, "failed")
            case STPSourceStatusUnknown:
                XCTAssertNil(string)
                break
            default:
                break
            }
        }
    }

    // MARK: - STPSourceUsage Tests

    func testUsageFromString() {
        XCTAssertEqual(Int(STPSource.usage(from: "reusable")), Int(STPSourceUsageReusable))
        XCTAssertEqual(Int(STPSource.usage(from: "REUSABLE")), Int(STPSourceUsageReusable))

        XCTAssertEqual(Int(STPSource.usage(from: "single_use")), Int(STPSourceUsageSingleUse))
        XCTAssertEqual(Int(STPSource.usage(from: "SINGLE_USE")), Int(STPSourceUsageSingleUse))

        XCTAssertEqual(Int(STPSource.usage(from: "garbage")), Int(STPSourceUsageUnknown))
        XCTAssertEqual(Int(STPSource.usage(from: "GARBAGE")), Int(STPSourceUsageUnknown))
    }

    func testStringFromUsage() {
        let values = [
            NSNumber(value: STPSourceUsageReusable),
            NSNumber(value: STPSourceUsageSingleUse),
            NSNumber(value: STPSourceUsageUnknown),
        ]

        for usageNumber in values {
            let usage = usageNumber.intValue as? STPSourceUsage
            let string = STPSource.string(from: usage)

            switch usage {
            case STPSourceUsageReusable:
                XCTAssertEqual(string, "reusable")
            case STPSourceUsageSingleUse:
                XCTAssertEqual(string, "single_use")
            case STPSourceUsageUnknown:
                XCTAssertNil(string)
                break
            default:
                break
            }
        }
    }

    // MARK: - Equality Tests

    func testSourceEquals() {
        let source1 = STPSource.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("AlipaySource"))
        let source2 = STPSource.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("AlipaySource"))

        XCTAssertNotEqual(source1, source2)

        XCTAssertEqual(source1, source1)
        XCTAssertEqual(source1, source2)

        XCTAssertEqual(source1?.hash ?? 0, source1?.hash ?? 0)
        XCTAssertEqual(source1?.hash ?? 0, source2?.hash ?? 0)
    }

    // MARK: - Description Tests

    func testDescription() {
        let source = STPSource.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("AlipaySource"))
        XCTAssert(source?.description)
    }

    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectFromAPIResponseRequiredFields() {
        let requiredFields = [
            "id",
            "livemode",
            "status",
            "type",
        ]

        for field in requiredFields {
            var response = STPTestUtils.jsonNamed("AlipaySource")
            response?.removeValue(forKey: field)

            XCTAssertNil(STPSource.decodedObject(fromAPIResponse: response))
        }

        XCTAssert(STPSource.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("AlipaySource")))
    }

    func testDecodingSource_3ds() {
        let response = STPTestUtils.jsonNamed(STPTestJSONSource3DS)
        let source = STPSource.decodedObject(fromAPIResponse: response)
        XCTAssertEqual(source?.stripeID, "src_456")
        XCTAssertEqual(source?.amount, NSNumber(value: 1099))
        XCTAssertEqual(source?.clientSecret, "src_client_secret_456")
        XCTAssertEqualWithAccuracy(source?.created.timeIntervalSince1970, 1483663790.0, 1.0)
        XCTAssertEqual(source?.currency, "eur")
        XCTAssertEqual(source?.flow ?? 0, Int(STPSourceFlowRedirect))
        XCTAssertEqual(source?.livemode ?? 0, Int(false))
        //#pragma clang diagnostic push
        //#pragma clang diagnostic ignored "-Wdeprecated"
        XCTAssertNil(source?.metadata ?? 0)
        //#pragma clang diagnostic pop
        XCTAssert(source?.owner) // STPSourceOwnerTest
        XCTAssert(source?.receiver) // STPSourceReceiverTest
        XCTAssert(source?.redirect) // STPSourceRedirectTest
        XCTAssertEqual(source?.status ?? 0, Int(STPSourceStatusPending))
        XCTAssertEqual(source?.type ?? 0, Int(STPSourceTypeThreeDSecure))
        XCTAssertEqual(source?.usage ?? 0, Int(STPSourceUsageSingleUse))
        XCTAssertNil(source?.verification ?? 0)
        var threedsecure = response?["three_d_secure"] as? [AnyHashable : Any]
        threedsecure?.removeValue(forKey: "customer") // should be nil
        XCTAssertEqual(source?.details, threedsecure)
        XCTAssertNil(source?.cardDetails ?? 0) // STPSourceCardDetailsTest
        XCTAssertNil(source?.sepaDebitDetails ?? 0) // STPSourceSEPADebitDetailsTest
        XCTAssertNotEqual(source?.allResponseFields, response) // Verify is copy
    }

    func testDecodingSource_alipay() {
        let response = STPTestUtils.jsonNamed(STPTestJSONSourceAlipay)
        let source = STPSource.decodedObject(fromAPIResponse: response)
        XCTAssertEqual(source?.stripeID, "src_123")
        XCTAssertEqual(source?.amount, NSNumber(value: 1099))
        XCTAssertEqual(source?.clientSecret, "src_client_secret_123")
        XCTAssertEqualWithAccuracy(source?.created.timeIntervalSince1970, 1445277809.0, 1.0)
        XCTAssertEqual(source?.currency, "usd")
        XCTAssertEqual(source?.flow ?? 0, Int(STPSourceFlowRedirect))
        XCTAssertEqual(source?.livemode ?? 0, Int(true))
        //#pragma clang diagnostic push
        //#pragma clang diagnostic ignored "-Wdeprecated"
        XCTAssertNil(source?.metadata ?? 0)
        //#pragma clang diagnostic pop
        XCTAssert(source?.owner) // STPSourceOwnerTest
        XCTAssertNil(source?.receiver ?? 0) // STPSourceReceiverTest
        XCTAssert(source?.redirect) // STPSourceRedirectTest
        XCTAssertEqual(source?.status ?? 0, Int(STPSourceStatusPending))
        XCTAssertEqual(source?.type ?? 0, Int(STPSourceTypeAlipay))
        XCTAssertEqual(source?.usage ?? 0, Int(STPSourceUsageSingleUse))
        XCTAssertNil(source?.verification ?? 0)
        var alipayResponse = response?["alipay"] as? [AnyHashable : Any]
        alipayResponse?.removeValue(forKey: "native_url") // should be nil
        alipayResponse?.removeValue(forKey: "statement_descriptor") // should be nil
        XCTAssertEqual(source?.details, alipayResponse)
        XCTAssertNil(source?.cardDetails ?? 0) // STPSourceCardDetailsTest
        XCTAssertNil(source?.sepaDebitDetails ?? 0) // STPSourceSEPADebitDetailsTest
        XCTAssertNotEqual(source?.allResponseFields, response) // Verify is copy
    }

    func testDecodingSource_card() {
        let response = STPTestUtils.jsonNamed(STPTestJSONSourceCard)
        let source = STPSource.decodedObject(fromAPIResponse: response)
        XCTAssertEqual(source?.stripeID, "src_123")
        XCTAssertNil(source?.amount ?? 0)
        XCTAssertEqual(source?.clientSecret, "src_client_secret_123")
        XCTAssertEqualWithAccuracy(source?.created.timeIntervalSince1970, 1483575790.0, 1.0)
        XCTAssertNil(source?.currency ?? 0)
        XCTAssertEqual(source?.flow ?? 0, Int(STPSourceFlowNone))
        XCTAssertEqual(source?.livemode ?? 0, Int(false))
        //#pragma clang diagnostic push
        //#pragma clang diagnostic ignored "-Wdeprecated"
        XCTAssertNil(source?.metadata ?? 0)
        //#pragma clang diagnostic pop
        XCTAssert(source?.owner) // STPSourceOwnerTest
        XCTAssertNil(source?.receiver ?? 0) // STPSourceReceiverTest
        XCTAssertNil(source?.redirect ?? 0) // STPSourceRedirectTest
        XCTAssertEqual(source?.status ?? 0, Int(STPSourceStatusChargeable))
        XCTAssertEqual(source?.type ?? 0, Int(STPSourceTypeCard))
        XCTAssertEqual(source?.usage ?? 0, Int(STPSourceUsageReusable))
        XCTAssertNil(source?.verification ?? 0)
        XCTAssertEqual(source?.details, response?["card"])
        XCTAssert(source?.cardDetails) // STPSourceCardDetailsTest
        XCTAssertNil(source?.sepaDebitDetails ?? 0) // STPSourceSEPADebitDetailsTest
        XCTAssertNotEqual(source?.allResponseFields, response) // Verify is copy
    }

    func testDecodingSource_ideal() {
        let response = STPTestUtils.jsonNamed(STPTestJSONSourceiDEAL)
        let source = STPSource.decodedObject(fromAPIResponse: response)
        XCTAssertEqual(source?.stripeID, "src_123")
        XCTAssertEqual(source?.amount, NSNumber(value: 1099))
        XCTAssertEqual(source?.clientSecret, "src_client_secret_123")
        XCTAssertEqualWithAccuracy(source?.created.timeIntervalSince1970, 1445277809.0, 1.0)
        XCTAssertEqual(source?.currency, "eur")
        XCTAssertEqual(source?.flow ?? 0, Int(STPSourceFlowRedirect))
        XCTAssertEqual(source?.livemode ?? 0, Int(true))
        //#pragma clang diagnostic push
        //#pragma clang diagnostic ignored "-Wdeprecated"
        XCTAssertNil(source?.metadata ?? 0)
        //#pragma clang diagnostic pop
        XCTAssert(source?.owner) // STPSourceOwnerTest
        XCTAssertNil(source?.receiver ?? 0) // STPSourceReceiverTest
        XCTAssert(source?.redirect) // STPSourceRedirectTest
        XCTAssertEqual(source?.status ?? 0, Int(STPSourceStatusPending))
        XCTAssertEqual(source?.type ?? 0, Int(STPSourceTypeiDEAL))
        XCTAssertEqual(source?.usage ?? 0, Int(STPSourceUsageSingleUse))
        XCTAssertNil(source?.verification ?? 0)
        XCTAssertEqual(source?.details, response?["ideal"])
        XCTAssertNil(source?.cardDetails ?? 0) // STPSourceCardDetailsTest
        XCTAssertNil(source?.sepaDebitDetails ?? 0) // STPSourceSEPADebitDetailsTest
        XCTAssertNotEqual(source?.allResponseFields, response) // Verify is copy
    }

    func testDecodingSource_sepa_debit() {
        let response = STPTestUtils.jsonNamed(STPTestJSONSourceSEPADebit)
        let source = STPSource.decodedObject(fromAPIResponse: response)
        XCTAssertEqual(source?.stripeID, "src_18HgGjHNCLa1Vra6Y9TIP6tU")
        XCTAssertNil(source?.amount ?? 0)
        XCTAssertEqual(source?.clientSecret, "src_client_secret_XcBmS94nTg5o0xc9MSliSlDW")
        XCTAssertEqualWithAccuracy(source?.created.timeIntervalSince1970, 1464803577.0, 1.0)
        XCTAssertEqual(source?.currency, "eur")
        XCTAssertEqual(source?.flow ?? 0, Int(STPSourceFlowNone))
        XCTAssertEqual(source?.livemode ?? 0, Int(false))
        //#pragma clang diagnostic push
        //#pragma clang diagnostic ignored "-Wdeprecated"
        XCTAssertNil(source?.metadata ?? 0)
        //#pragma clang diagnostic pop
        XCTAssertEqual(source?.owner.name, "Jenny Rosen")
        XCTAssert(source?.owner) // STPSourceOwnerTest
        XCTAssertNil(source?.receiver ?? 0) // STPSourceReceiverTest
        XCTAssertNil(source?.redirect ?? 0) // STPSourceRedirectTest
        XCTAssertEqual(source?.status ?? 0, Int(STPSourceStatusChargeable))
        XCTAssertEqual(source?.type ?? 0, Int(STPSourceTypeSEPADebit))
        XCTAssertEqual(source?.usage ?? 0, Int(STPSourceUsageReusable))
        XCTAssertEqual(source?.verification.attemptsRemaining, NSNumber(value: 5))
        XCTAssertEqual(source?.verification.status ?? 0, Int(STPSourceVerificationStatusPending))
        XCTAssertEqual(source?.details, response?["sepa_debit"])
        XCTAssertNil(source?.cardDetails ?? 0) // STPSourceCardDetailsTest
        XCTAssert(source?.sepaDebitDetails) // STPSourceSEPADebitDetailsTest
        XCTAssertNotEqual(source?.allResponseFields, response) // Verify is copy
    }

    // MARK: - STPPaymentOption Tests

    func possibleAPIResponses() -> [AnyHashable]? {
        return [
            STPTestUtils.jsonNamed(STPTestJSONSourceCard),
            STPTestUtils.jsonNamed(STPTestJSONSource3DS),
            STPTestUtils.jsonNamed(STPTestJSONSourceAlipay),
            STPTestUtils.jsonNamed(STPTestJSONSourceBancontact),
            STPTestUtils.jsonNamed(STPTestJSONSourceEPS),
            STPTestUtils.jsonNamed(STPTestJSONSourceGiropay),
            STPTestUtils.jsonNamed(STPTestJSONSourceiDEAL),
            STPTestUtils.jsonNamed(STPTestJSONSourceMultibanco),
            STPTestUtils.jsonNamed(STPTestJSONSourceP24),
            STPTestUtils.jsonNamed(STPTestJSONSourceSEPADebit),
            STPTestUtils.jsonNamed(STPTestJSONSourceSofort)
        ]
    }

    func testPaymentOptionImage() {
        for response in possibleAPIResponses() ?? [] {
            guard let response = response as? [AnyHashable : Any] else {
                continue
            }
            let source = STPSource.decodedObject(fromAPIResponse: response)

            switch source?.type {
            case STPSourceTypeCard:
                STPAssertEqualImages(source?.image, STPImageLibrary.brandImage(forCardBrand: source?.cardDetails.brand))
            default:
                STPAssertEqualImages(source?.image, STPImageLibrary.brandImage(for: STPCardBrand.unknown))
            }
        }
    }

    func testPaymentOptionTemplateImage() {
        for response in possibleAPIResponses() ?? [] {
            guard let response = response as? [AnyHashable : Any] else {
                continue
            }
            let source = STPSource.decodedObject(fromAPIResponse: response)

            switch source?.type {
            case STPSourceTypeCard:
                STPAssertEqualImages(source?.templateImage, STPImageLibrary.templatedBrandImage(forCardBrand: source?.cardDetails.brand))
            default:
                STPAssertEqualImages(source?.templateImage, STPImageLibrary.templatedBrandImage(for: STPCardBrand.unknown))
            }
        }
    }

    func testPaymentOptionLabel() {
        for response in possibleAPIResponses() ?? [] {
            guard let response = response as? [AnyHashable : Any] else {
                continue
            }
            let source = STPSource.decodedObject(fromAPIResponse: response)

            switch source?.type {
            case STPSourceTypeBancontact:
                XCTAssertEqual(source?.label, "Bancontact")
            case STPSourceTypeCard:
                XCTAssertEqual(source?.label, "Visa 5556")
            case STPSourceTypeGiropay:
                XCTAssertEqual(source?.label, "giropay")
            case STPSourceTypeiDEAL:
                XCTAssertEqual(source?.label, "iDEAL")
            case STPSourceTypeSEPADebit:
                XCTAssertEqual(source?.label, "SEPA Debit")
            case STPSourceTypeSofort:
                XCTAssertEqual(source?.label, "Sofort")
            case STPSourceTypeThreeDSecure:
                XCTAssertEqual(source?.label, "3D Secure")
            case STPSourceTypeAlipay:
                XCTAssertEqual(source?.label, "Alipay")
            case STPSourceTypeP24:
                XCTAssertEqual(source?.label, "Przelewy24")
            case STPSourceTypeEPS:
                XCTAssertEqual(source?.label, "EPS")
            case STPSourceTypeMultibanco:
                XCTAssertEqual(source?.label, "Multibanco")
            case STPSourceTypeWeChatPay:
                XCTAssertEqual(source?.label, "WeChat Pay")
            case STPSourceTypeKlarna:
                XCTAssertEqual(source?.label, "Klarna")
            case STPSourceTypeUnknown:
                XCTAssertEqual(source?.label, STPCard.string(from: STPCardBrand.unknown))
            default:
                break
            }
        }
    }
}