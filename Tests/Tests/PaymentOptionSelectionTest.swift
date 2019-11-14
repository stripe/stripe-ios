//
//  PaymentOptionSelectionTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 11/14/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import XCTest
import Stripe

class PaymentOptionSelectionTest: XCTestCase {
    func testCodable() {
        let suts = [
            PaymentOptionSelection.applePay,
            PaymentOptionSelection.reusablePaymentMethod(paymentMethodID: "pm_1234"),
            PaymentOptionSelection.FPX(bank: .bankIslam)
        ]
        for sut in suts {
            do {
                // Encoding a PaymentOptionSelection to JSON data...
                let encoded = try JSONEncoder().encode(sut)
                print(try JSONSerialization.jsonObject(with: encoded, options: []))
                // ...and decoding it back to a PaymentOptionSelection...
                let decoded = try JSONDecoder().decode(PaymentOptionSelection.self, from: encoded)
                // ...should produce the original
                XCTAssertEqual(decoded, sut)
            } catch {
                XCTFail("Error coding \(sut): \(error)")
            }
        }
    }
}
