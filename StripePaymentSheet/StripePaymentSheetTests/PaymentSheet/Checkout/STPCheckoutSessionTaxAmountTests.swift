//
//  STPCheckoutSessionTaxAmountTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 3/5/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable @_spi(STP) import StripePayments
@testable @_spi(STP) @_spi(CheckoutSessionsPreview) import StripePaymentSheet
import XCTest

final class STPCheckoutSessionTaxAmountTests: XCTestCase {

    func testDecodeTaxRateSuccess() {
        let dict: [AnyHashable: Any] = [
            "display_name": "Sales Tax",
            "percentage": 9.875,
            "jurisdiction": "UT",
        ]

        let taxRate = STPCheckoutSessionTaxRate.decode(from: dict)
        XCTAssertNotNil(taxRate)
        XCTAssertEqual(taxRate?.displayName, "Sales Tax")
        XCTAssertEqual(taxRate?.percentage, 9.875)
        XCTAssertEqual(taxRate?.jurisdiction, "UT")
    }

    func testDecodeTaxRateFailure() {
        let dict: [AnyHashable: Any] = [
            "display_name": "Sales Tax",
            "jurisdiction": "UT",
        ]

        let taxRate = STPCheckoutSessionTaxRate.decode(from: dict)
        XCTAssertNil(taxRate)
    }

    func testDecodeTaxAmountSuccess() {
        let dict: [AnyHashable: Any] = [
            "line_item_group": [
                "tax_amounts": [
                    [
                        "amount": 1185,
                        "inclusive": false,
                        "taxable_amount": 12000,
                        "tax_rate": [
                            "display_name": "Sales Tax",
                            "percentage": 9.875,
                            "jurisdiction": "UT",
                        ],
                    ],
                ],
            ],
        ]

        let taxAmounts = STPCheckoutSessionTaxAmount.taxAmounts(from: dict)
        XCTAssertEqual(taxAmounts.count, 1)

        let taxAmount = taxAmounts[0]
        XCTAssertEqual(taxAmount.amount, 1185)
        XCTAssertFalse(taxAmount.inclusive)
        XCTAssertEqual(taxAmount.taxableAmount, 12000)
        XCTAssertEqual(taxAmount.taxRate?.displayName, "Sales Tax")
        XCTAssertEqual(taxAmount.taxRate?.percentage, 9.875)
        XCTAssertEqual(taxAmount.taxRate?.jurisdiction, "UT")
    }

    func testDecodeTaxAmountFailureMissingFields() {
        let dict: [AnyHashable: Any] = [
            "line_item_group": [
                "tax_amounts": [
                    [
                        "amount": 1185,
                        "inclusive": false,
                        // Missing taxable_amount
                    ],
                ],
            ],
        ]

        let taxAmounts = STPCheckoutSessionTaxAmount.taxAmounts(from: dict)
        XCTAssertTrue(taxAmounts.isEmpty)
    }

    func testDecodeTaxAmountEmptyList() {
        let dict: [AnyHashable: Any] = [
            "line_item_group": [
                "tax_amounts": []
            ],
        ]

        let taxAmounts = STPCheckoutSessionTaxAmount.taxAmounts(from: dict)
        XCTAssertTrue(taxAmounts.isEmpty)
    }

    func testHashableAndEquatable() {
        let rate1 = STPCheckoutSessionTaxRate(displayName: "A", percentage: 5.0, jurisdiction: "CA")
        let rate2 = STPCheckoutSessionTaxRate(displayName: "A", percentage: 5.0, jurisdiction: "CA")
        let rate3 = STPCheckoutSessionTaxRate(displayName: "B", percentage: 5.0, jurisdiction: "CA")

        XCTAssertEqual(rate1, rate2)
        XCTAssertNotEqual(rate1, rate3)
        XCTAssertEqual(rate1.hashValue, rate2.hashValue)
        XCTAssertNotEqual(rate1.hashValue, rate3.hashValue)

        let amount1 = STPCheckoutSessionTaxAmount(amount: 100, inclusive: true, taxableAmount: 2000, taxRate: rate1)
        let amount2 = STPCheckoutSessionTaxAmount(amount: 100, inclusive: true, taxableAmount: 2000, taxRate: rate2)
        let amount3 = STPCheckoutSessionTaxAmount(amount: 100, inclusive: true, taxableAmount: 2000, taxRate: rate3)

        XCTAssertEqual(amount1, amount2)
        XCTAssertNotEqual(amount1, amount3)
        XCTAssertEqual(amount1.hashValue, amount2.hashValue)
        XCTAssertNotEqual(amount1.hashValue, amount3.hashValue)
    }
}
