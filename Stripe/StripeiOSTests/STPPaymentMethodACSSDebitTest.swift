//
//  STPPaymentMethodACSSDebitTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 8/27/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

final class STPPaymentMethodACSSDebitTest: XCTestCase {
    func testParamsEncoding() {
        let acssDebit = STPPaymentMethodACSSDebitParams()
        acssDebit.institutionNumber = "000"
        acssDebit.transitNumber = "11000"
        acssDebit.accountNumber = "000123456789"
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jenny Rosen"
        billingDetails.email = "jrosen@example.com"
        let params = STPPaymentMethodParams(
            acssDebit: acssDebit,
            billingDetails: billingDetails,
            metadata: nil
        )

        let encoded = STPFormEncoder.dictionary(forObject: params)

        XCTAssertEqual(encoded["type"] as? String, "acss_debit")
        XCTAssertEqual(encoded["acss_debit"] as? [String: String], [
            "account_number": "000123456789",
            "institution_number": "000",
            "transit_number": "11000",
        ])
        XCTAssertEqual((encoded["billing_details"] as? [String: Any])?["name"] as? String, "Jenny Rosen")
        XCTAssertEqual((encoded["billing_details"] as? [String: Any])?["email"] as? String, "jrosen@example.com")
    }

    func testDecoding() {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_acss",
            "created": 1_725_000_000,
            "type": "acss_debit",
            "acss_debit": [
                "bank_name": "STRIPE TEST BANK",
                "fingerprint": "fingerprint",
                "institution_number": "000",
                "last4": "6789",
                "transit_number": "11000",
            ],
        ])

        XCTAssertEqual(paymentMethod?.type, .ACSSDebit)
        XCTAssertEqual(paymentMethod?.acssDebit?.bankName, "STRIPE TEST BANK")
        XCTAssertEqual(paymentMethod?.acssDebit?.fingerprint, "fingerprint")
        XCTAssertEqual(paymentMethod?.acssDebit?.institutionNumber, "000")
        XCTAssertEqual(paymentMethod?.acssDebit?.last4, "6789")
        XCTAssertEqual(paymentMethod?.acssDebit?.transitNumber, "11000")
    }

    func testDecodingAllowsNullBankDetails() {
        let response: [AnyHashable: Any] = [
            "bank_name": NSNull(),
            "fingerprint": NSNull(),
            "institution_number": NSNull(),
            "last4": NSNull(),
            "transit_number": NSNull(),
        ]

        let acssDebit = STPPaymentMethodACSSDebit.decodedObject(fromAPIResponse: response)

        XCTAssertNotNil(acssDebit)
        XCTAssertNil(acssDebit?.bankName)
        XCTAssertNil(acssDebit?.fingerprint)
        XCTAssertNil(acssDebit?.institutionNumber)
        XCTAssertNil(acssDebit?.last4)
        XCTAssertNil(acssDebit?.transitNumber)
    }

    func testDecodesMicrodepositVerificationWithoutType() {
        let action = STPIntentAction.decodedObject(fromAPIResponse: [
            "type": "verify_with_microdeposits",
            "verify_with_microdeposits": [
                "arrival_date": 1_725_000_000,
                "hosted_verification_url": "https://payments.stripe.com/microdeposit/test",
            ],
        ])

        XCTAssertEqual(action?.type, .verifyWithMicrodeposits)
        XCTAssertEqual(action?.verifyWithMicrodeposits?.microdepositType, .unknown)
    }
}
