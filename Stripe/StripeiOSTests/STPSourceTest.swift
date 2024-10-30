//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPSourceTest.m
//  Stripe
//
//  Created by Ben Guo on 1/24/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@testable import StripePayments
@testable import StripePaymentsUI
import XCTest

class STPSourceTest: XCTestCase {
    // MARK: - STPSourceType Tests

    func testTypeFromString() {
        XCTAssertEqual(STPSource.type(from: "bancontact"), STPSourceType.bancontact)
        XCTAssertEqual(STPSource.type(from: "BANCONTACT"), STPSourceType.bancontact)

        XCTAssertEqual(STPSource.type(from: "card"), STPSourceType.card)
        XCTAssertEqual(STPSource.type(from: "CARD"), STPSourceType.card)

        XCTAssertEqual(STPSource.type(from: "giropay"), STPSourceType.giropay)
        XCTAssertEqual(STPSource.type(from: "GIROPAY"), STPSourceType.giropay)

        XCTAssertEqual(STPSource.type(from: "ideal"), STPSourceType.iDEAL)
        XCTAssertEqual(STPSource.type(from: "IDEAL"), STPSourceType.iDEAL)

        XCTAssertEqual(STPSource.type(from: "sepa_debit"), STPSourceType.SEPADebit)
        XCTAssertEqual(STPSource.type(from: "SEPA_DEBIT"), STPSourceType.SEPADebit)

        XCTAssertEqual(STPSource.type(from: "sofort"), STPSourceType.sofort)
        XCTAssertEqual(STPSource.type(from: "Sofort"), STPSourceType.sofort)

        XCTAssertEqual(STPSource.type(from: "three_d_secure"), STPSourceType.threeDSecure)
        XCTAssertEqual(STPSource.type(from: "THREE_D_SECURE"), STPSourceType.threeDSecure)

        XCTAssertEqual(STPSource.type(from: "alipay"), STPSourceType.alipay)
        XCTAssertEqual(STPSource.type(from: "ALIPAY"), STPSourceType.alipay)

        XCTAssertEqual(STPSource.type(from: "p24"), STPSourceType.P24)
        XCTAssertEqual(STPSource.type(from: "P24"), STPSourceType.P24)

        XCTAssertEqual(STPSource.type(from: "eps"), STPSourceType.EPS)
        XCTAssertEqual(STPSource.type(from: "EPS"), STPSourceType.EPS)

        XCTAssertEqual(STPSource.type(from: "multibanco"), STPSourceType.multibanco)
        XCTAssertEqual(STPSource.type(from: "MULTIBANCO"), STPSourceType.multibanco)

        XCTAssertEqual(STPSource.type(from: "unknown"), STPSourceType.unknown)
        XCTAssertEqual(STPSource.type(from: "UNKNOWN"), STPSourceType.unknown)

        XCTAssertEqual(STPSource.type(from: "garbage"), STPSourceType.unknown)
        XCTAssertEqual(STPSource.type(from: "GARBAGE"), STPSourceType.unknown)
    }

    func testStringFromType() {
        let values = [
            STPSourceType.bancontact,
            STPSourceType.card,
            STPSourceType.giropay,
            STPSourceType.iDEAL,
            STPSourceType.SEPADebit,
            STPSourceType.sofort,
            STPSourceType.threeDSecure,
            STPSourceType.alipay,
            STPSourceType.P24,
            STPSourceType.EPS,
            STPSourceType.multibanco,
            STPSourceType.unknown,
        ]

        for type in values {
            let string = STPSource.string(from: type)

            switch type {
            case STPSourceType.bancontact:
                XCTAssertEqual(string, "bancontact")
            case STPSourceType.card:
                XCTAssertEqual(string, "card")
            case STPSourceType.giropay:
                XCTAssertEqual(string, "giropay")
            case STPSourceType.iDEAL:
                XCTAssertEqual(string, "ideal")
            case STPSourceType.SEPADebit:
                XCTAssertEqual(string, "sepa_debit")
            case STPSourceType.sofort:
                XCTAssertEqual(string, "sofort")
            case STPSourceType.threeDSecure:
                XCTAssertEqual(string, "three_d_secure")
            case STPSourceType.alipay:
                XCTAssertEqual(string, "alipay")
            case STPSourceType.P24:
                XCTAssertEqual(string, "p24")
            case STPSourceType.EPS:
                XCTAssertEqual(string, "eps")
            case STPSourceType.multibanco:
                XCTAssertEqual(string, "multibanco")
            case STPSourceType.weChatPay:
                XCTAssertEqual(string, "wechat")
            case STPSourceType.klarna:
                XCTAssertEqual(string, "klarna")
            case STPSourceType.unknown:
                XCTAssertNil(string)
            default:
                break
            }
        }
    }

    // MARK: - STPSourceFlow Tests

    func testFlowFromString() {
        XCTAssertEqual(STPSource.flow(from: "redirect"), .redirect)
        XCTAssertEqual(STPSource.flow(from: "REDIRECT"), .redirect)

        XCTAssertEqual(STPSource.flow(from: "receiver"), .receiver)
        XCTAssertEqual(STPSource.flow(from: "RECEIVER"), .receiver)

        XCTAssertEqual(STPSource.flow(from: "code_verification"), .codeVerification)
        XCTAssertEqual(STPSource.flow(from: "CODE_VERIFICATION"), .codeVerification)

        XCTAssertEqual(STPSource.flow(from: "none"), .none)
        XCTAssertEqual(STPSource.flow(from: "NONE"), .none)

        XCTAssertEqual(STPSource.flow(from: "garbage"), .unknown)
        XCTAssertEqual(STPSource.flow(from: "GARBAGE"), .unknown)
    }

    func testStringFromFlow() {
        let values: [STPSourceFlow] = [
            .redirect,
            .receiver,
            .codeVerification,
            .none,
            .unknown,
        ]

        for flow in values {
            let string = STPSource.string(from: flow)

            switch flow {
            case .redirect:
                XCTAssertEqual(string, "redirect")
            case .receiver:
                XCTAssertEqual(string, "receiver")
            case .codeVerification:
                XCTAssertEqual(string, "code_verification")
            case .none:
                XCTAssertEqual(string, "none")
            case .unknown:
                XCTAssertNil(string)
            default:
                break
            }
        }
    }

    // MARK: - STPSourceStatus Tests

    func testStatusFromString() {
        XCTAssertEqual(STPSource.status(from: "pending"), STPSourceStatus.pending)
        XCTAssertEqual(STPSource.status(from: "PENDING"), STPSourceStatus.pending)

        XCTAssertEqual(STPSource.status(from: "chargeable"), STPSourceStatus.chargeable)
        XCTAssertEqual(STPSource.status(from: "CHARGEABLE"), STPSourceStatus.chargeable)

        XCTAssertEqual(STPSource.status(from: "consumed"), STPSourceStatus.consumed)
        XCTAssertEqual(STPSource.status(from: "CONSUMED"), STPSourceStatus.consumed)

        XCTAssertEqual(STPSource.status(from: "canceled"), STPSourceStatus.canceled)
        XCTAssertEqual(STPSource.status(from: "CANCELED"), STPSourceStatus.canceled)

        XCTAssertEqual(STPSource.status(from: "failed"), STPSourceStatus.failed)
        XCTAssertEqual(STPSource.status(from: "FAILED"), STPSourceStatus.failed)

        XCTAssertEqual(STPSource.status(from: "garbage"), STPSourceStatus.unknown)
        XCTAssertEqual(STPSource.status(from: "GARBAGE"), STPSourceStatus.unknown)
    }

    func testStringFromStatus() {
        let values = [
            STPSourceStatus.pending,
            STPSourceStatus.chargeable,
            STPSourceStatus.consumed,
            STPSourceStatus.canceled,
            STPSourceStatus.failed,
            STPSourceStatus.unknown,
        ]

        for status in values {
            let string = STPSource.string(from: status)

            switch status {
            case STPSourceStatus.pending:
                XCTAssertEqual(string, "pending")
            case STPSourceStatus.chargeable:
                XCTAssertEqual(string, "chargeable")
            case STPSourceStatus.consumed:
                XCTAssertEqual(string, "consumed")
            case STPSourceStatus.canceled:
                XCTAssertEqual(string, "canceled")
            case STPSourceStatus.failed:
                XCTAssertEqual(string, "failed")
            case STPSourceStatus.unknown:
                XCTAssertNil(string)
            default:
                break
            }
        }
    }

    // MARK: - STPSourceUsage Tests

    func testUsageFromString() {
        XCTAssertEqual(STPSource.usage(from: "reusable"), STPSourceUsage.reusable)
        XCTAssertEqual(STPSource.usage(from: "REUSABLE"), STPSourceUsage.reusable)

        XCTAssertEqual(STPSource.usage(from: "single_use"), STPSourceUsage.singleUse)
        XCTAssertEqual(STPSource.usage(from: "SINGLE_USE"), STPSourceUsage.singleUse)

        XCTAssertEqual(STPSource.usage(from: "garbage"), STPSourceUsage.unknown)
        XCTAssertEqual(STPSource.usage(from: "GARBAGE"), STPSourceUsage.unknown)
    }

    func testStringFromUsage() {
        let values = [
            STPSourceUsage.reusable,
            STPSourceUsage.singleUse,
            STPSourceUsage.unknown,
        ]

        for usage in values {
            let string = STPSource.string(from: usage)

            switch usage {
            case STPSourceUsage.reusable:
                XCTAssertEqual(string, "reusable")
            case STPSourceUsage.singleUse:
                XCTAssertEqual(string, "single_use")
            case STPSourceUsage.unknown:
                XCTAssertNil(string)
            default:
                break
            }
        }
    }

    // MARK: - Equality Tests

    func testSourceEquals() {
        let source1 = STPSource.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("AlipaySource"))
        let source2 = STPSource.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("AlipaySource"))

        XCTAssertEqual(source1, source1)
        XCTAssertEqual(source1, source2)

        XCTAssertEqual(source1?.hash, source1?.hash)
        XCTAssertEqual(source1?.hash, source2?.hash)
    }

    // MARK: - Description Tests

    func testDescription() {
        let source = STPSource.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("AlipaySource"))
        XCTAssertNotNil(source?.description)
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

        XCTAssertNotNil(STPSource.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("AlipaySource")))
    }

    func testDecodingSource_3ds() {
        let response = STPTestUtils.jsonNamed(STPTestJSONSource3DS)
        let source = STPSource.decodedObject(fromAPIResponse: response)
        XCTAssertEqual(source?.stripeID, "src_456")
        XCTAssertEqual(source?.amount, NSNumber(value: 1099))
        XCTAssertEqual(source?.clientSecret, "src_client_secret_456")
        XCTAssertEqual(source?.created?.timeIntervalSince1970 ?? 0, 1483663790.0, accuracy: 1.0)
        XCTAssertEqual(source?.currency, "eur")
        XCTAssertEqual(source?.flow, .redirect)
        XCTAssertEqual(source?.livemode, false)
        XCTAssertNil(source?.perform(NSSelectorFromString("metadata")))
        XCTAssertNotNil(source?.owner) // STPSourceOwnerTest
        XCTAssertNotNil(source?.receiver) // STPSourceReceiverTest
        XCTAssertNotNil(source?.redirect) // STPSourceRedirectTest
        XCTAssertEqual(source?.status, STPSourceStatus.pending)
        XCTAssertEqual(source?.type, STPSourceType.threeDSecure)
        XCTAssertEqual(source?.usage, STPSourceUsage.singleUse)
        XCTAssertNil(source?.verification)
        var threedsecure = response?["three_d_secure"] as? [AnyHashable: Any]
        threedsecure?.removeValue(forKey: "customer") // should be nil
//        XCTAssertEqual(source?.details, threedsecure)
        XCTAssertNotNil(source?.details)
        XCTAssertNil(source?.cardDetails) // STPSourceCardDetailsTest
        XCTAssertNil(source?.sepaDebitDetails) // STPSourceSEPADebitDetailsTest
    }

    func testDecodingSource_alipay() {
        let response = STPTestUtils.jsonNamed(STPTestJSONSourceAlipay)
        let source = STPSource.decodedObject(fromAPIResponse: response)
        XCTAssertEqual(source?.stripeID, "src_123")
        XCTAssertEqual(source?.amount, NSNumber(value: 1099))
        XCTAssertEqual(source?.clientSecret, "src_client_secret_123")
        XCTAssertEqual(source?.created?.timeIntervalSince1970 ?? 0, 1445277809.0, accuracy: 1.0)
        XCTAssertEqual(source?.currency, "usd")
        XCTAssertEqual(source?.flow, .redirect)
        XCTAssertEqual(source?.livemode, true)
        XCTAssertNil(source?.perform(NSSelectorFromString("metadata")))
        XCTAssertNotNil(source?.owner) // STPSourceOwnerTest
        XCTAssertNil(source?.receiver) // STPSourceReceiverTest
        XCTAssertNotNil(source?.redirect) // STPSourceRedirectTest
        XCTAssertEqual(source?.status, STPSourceStatus.pending)
        XCTAssertEqual(source?.type, STPSourceType.alipay)
        XCTAssertEqual(source?.usage, STPSourceUsage.singleUse)
        XCTAssertNil(source?.verification)
        var alipayResponse = response!["alipay"] as? [AnyHashable: Any]
        alipayResponse?.removeValue(forKey: "native_url") // should be nil
        alipayResponse?.removeValue(forKey: "statement_descriptor") // should be nil
        XCTAssertEqual(source!.details! as NSDictionary, alipayResponse! as NSDictionary)
        XCTAssertNil(source?.cardDetails) // STPSourceCardDetailsTest
        XCTAssertNil(source?.sepaDebitDetails) // STPSourceSEPADebitDetailsTest
    }

    func testDecodingSource_card() {
        let response = STPTestUtils.jsonNamed(STPTestJSONSourceCard)
        let source = STPSource.decodedObject(fromAPIResponse: response)
        XCTAssertEqual(source?.stripeID, "src_123")
        XCTAssertNil(source?.amount)
        XCTAssertEqual(source?.clientSecret, "src_client_secret_123")
        XCTAssertEqual(source?.created?.timeIntervalSince1970 ?? 0, 1483575790.0, accuracy: 1.0)
        XCTAssertNil(source?.currency)
        XCTAssertEqual(source?.flow, STPSourceFlow.none)
        XCTAssertEqual(source?.livemode, false)
        XCTAssertNil(source?.perform(NSSelectorFromString("metadata")))
        XCTAssertNotNil(source?.owner) // STPSourceOwnerTest
        XCTAssertNil(source?.receiver) // STPSourceReceiverTest
        XCTAssertNil(source?.redirect) // STPSourceRedirectTest
        XCTAssertEqual(source?.status, STPSourceStatus.chargeable)
        XCTAssertEqual(source?.type, STPSourceType.card)
        XCTAssertEqual(source?.usage, STPSourceUsage.reusable)
        XCTAssertNil(source?.verification)
        XCTAssertEqual(source!.details! as NSDictionary, response!["card"] as! NSDictionary)
        XCTAssertNotNil(source?.cardDetails) // STPSourceCardDetailsTest
        XCTAssertNil(source?.sepaDebitDetails) // STPSourceSEPADebitDetailsTest
    }

    func testDecodingSource_ideal() {
        let response = STPTestUtils.jsonNamed(STPTestJSONSourceiDEAL)
        let source = STPSource.decodedObject(fromAPIResponse: response)
        XCTAssertEqual(source?.stripeID, "src_123")
        XCTAssertEqual(source?.amount, NSNumber(value: 1099))
        XCTAssertEqual(source?.clientSecret, "src_client_secret_123")
        XCTAssertEqual(source?.created?.timeIntervalSince1970 ?? 0, 1445277809.0, accuracy: 1.0)
        XCTAssertEqual(source?.currency, "eur")
        XCTAssertEqual(source?.flow, .redirect)
        XCTAssertEqual(source?.livemode, true)
        XCTAssertNil(source?.perform(NSSelectorFromString("metadata")))
        XCTAssertNotNil(source?.owner) // STPSourceOwnerTest
        XCTAssertNil(source?.receiver) // STPSourceReceiverTest
        XCTAssertNotNil(source?.redirect) // STPSourceRedirectTest
        XCTAssertEqual(source?.status, STPSourceStatus.pending)
        XCTAssertEqual(source?.type, STPSourceType.iDEAL)
        XCTAssertEqual(source?.usage, STPSourceUsage.singleUse)
        XCTAssertNil(source?.verification)
        XCTAssertEqual(source!.details! as NSDictionary, response!["ideal"] as! NSDictionary)
        XCTAssertNil(source?.cardDetails) // STPSourceCardDetailsTest
        XCTAssertNil(source?.sepaDebitDetails) // STPSourceSEPADebitDetailsTest
    }

    func testDecodingSource_sepa_debit() {
        let response = STPTestUtils.jsonNamed(STPTestJSONSourceSEPADebit)
        let source = STPSource.decodedObject(fromAPIResponse: response)
        XCTAssertEqual(source?.stripeID, "src_18HgGjHNCLa1Vra6Y9TIP6tU")
        XCTAssertNil(source?.amount)
        XCTAssertEqual(source?.clientSecret, "src_client_secret_XcBmS94nTg5o0xc9MSliSlDW")
        XCTAssertEqual(source?.created?.timeIntervalSince1970 ?? 0, 1464803577.0, accuracy: 1.0)
        XCTAssertEqual(source?.currency, "eur")
        XCTAssertEqual(source?.flow, STPSourceFlow.none)
        XCTAssertEqual(source?.livemode, false)
        XCTAssertNil(source?.perform(NSSelectorFromString("metadata")))
        XCTAssertEqual(source?.owner?.name, "Jenny Rosen")
        XCTAssertNotNil(source?.owner) // STPSourceOwnerTest
        XCTAssertNil(source?.receiver) // STPSourceReceiverTest
        XCTAssertNil(source?.redirect) // STPSourceRedirectTest
        XCTAssertEqual(source?.status, STPSourceStatus.chargeable)
        XCTAssertEqual(source?.type, STPSourceType.SEPADebit)
        XCTAssertEqual(source?.usage, STPSourceUsage.reusable)
        XCTAssertEqual(source?.verification?.attemptsRemaining, NSNumber(value: 5))
        XCTAssertEqual(source?.verification?.status, STPSourceVerificationStatus.pending)
        XCTAssertEqual(source!.details! as NSDictionary, response!["sepa_debit"] as! NSDictionary)
        XCTAssertNil(source?.cardDetails) // STPSourceCardDetailsTest
        XCTAssertNotNil(source?.sepaDebitDetails) // STPSourceSEPADebitDetailsTest
    }

    func possibleAPIResponses() -> [[AnyHashable: Any]] {
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
            STPTestUtils.jsonNamed(STPTestJSONSourceSofort),
        ]
    }

}
