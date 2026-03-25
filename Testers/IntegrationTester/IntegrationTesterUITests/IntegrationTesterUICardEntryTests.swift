//
//  IntegrationTesterUICardEntryTests.swift
//  
//
//  Created by David Estes on 2/11/26.
//

import IntegrationTesterCommon
import Stripe
import XCTest

class IntegrationTesterUICardEntryTests: IntegrationTesterUITests {
    func testNoAuthenticationCustomCard() throws {
        let cardNumbers = [
            // Main test cards
            "4242424242424242", // visa
            "4000056655665556", // visa (debit)
            "5555555555554444", // mastercard
            "2223003122003222", // mastercard (2-series)
            "5200828282828210", // mastercard (debit)
            "5105105105105100", // mastercard (prepaid)
            "378282246310005",  // amex
            "371449635398431",  // amex
            "6011111111111117", // discover
            "6011000990139424", // discover
            "3056930009020004", // diners club
            "36227206271667",   // diners club (14 digit)
            "3566002020360505", // jcb
            "6200000000000005", // cup

            // Non-US
            "4000000760000002", // br
            "4000001240000000", // ca
            "4000004840008001", // mx
        ]
        for card in cardNumbers {
            testAuthentication(cardNumber: card)
        }
    }
}
