//
//  STPCheckoutSessionDiscountTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripePayments
import XCTest

final class STPCheckoutSessionDiscountTests: XCTestCase {

    // MARK: - Valid discount with coupon + promotion code

    func testParseDiscountWithCouponAndPromotionCode() {
        let dict: [AnyHashable: Any] = [
            "line_item_group": [
                "discount_amounts": [
                    [
                        "amount": 500,
                        "coupon": [
                            "name": "25% Off",
                            "percent_off": 25.0,
                        ] as [String: Any],
                        "promotion_code": [
                            "code": "SAVE25",
                        ],
                    ] as [String: Any],
                ],
            ],
        ]

        let discounts = STPCheckoutSessionDiscount.discounts(from: dict)
        XCTAssertEqual(discounts.count, 1)

        let discount = discounts[0]
        XCTAssertEqual(discount.id, "discount_0")
        XCTAssertEqual(discount.name, "25% Off")
        XCTAssertEqual(discount.promotionCode?.code, "SAVE25")
        XCTAssertEqual(discount.amount, 500)
        XCTAssertEqual(discount.percentOff, 25.0)
        XCTAssertNil(discount.amountOff)
    }

    // MARK: - Discount with coupon only (no promotion code)

    func testParseDiscountWithCouponOnly() {
        let dict: [AnyHashable: Any] = [
            "line_item_group": [
                "discount_amounts": [
                    [
                        "amount": 1000,
                        "coupon": [
                            "name": "$10 Off",
                            "amount_off": 1000,
                        ] as [String: Any],
                    ] as [String: Any],
                ],
            ],
        ]

        let discounts = STPCheckoutSessionDiscount.discounts(from: dict)
        XCTAssertEqual(discounts.count, 1)

        let discount = discounts[0]
        XCTAssertEqual(discount.id, "discount_0")
        XCTAssertEqual(discount.name, "$10 Off")
        XCTAssertNil(discount.promotionCode)
        XCTAssertEqual(discount.amount, 1000)
        XCTAssertNil(discount.percentOff)
        XCTAssertEqual(discount.amountOff, 1000)
    }

    // MARK: - Zero amount is filtered out

    func testZeroAmountDiscountIsFiltered() {
        let dict: [AnyHashable: Any] = [
            "line_item_group": [
                "discount_amounts": [
                    [
                        "amount": 0,
                        "coupon": [
                            "name": "No-op",
                        ],
                    ] as [String: Any],
                ],
            ],
        ]

        let discounts = STPCheckoutSessionDiscount.discounts(from: dict)
        XCTAssertTrue(discounts.isEmpty)
    }

    // MARK: - Empty discount_amounts array

    func testEmptyDiscountAmountsArray() {
        let dict: [AnyHashable: Any] = [
            "line_item_group": [
                "discount_amounts": [] as [[AnyHashable: Any]],
            ],
        ]

        let discounts = STPCheckoutSessionDiscount.discounts(from: dict)
        XCTAssertTrue(discounts.isEmpty)
    }

    // MARK: - Missing line_item_group key

    func testMissingLineItemGroup() {
        let dict: [AnyHashable: Any] = [
            "session_id": "cs_test_123",
        ]

        let discounts = STPCheckoutSessionDiscount.discounts(from: dict)
        XCTAssertTrue(discounts.isEmpty)
    }

    // MARK: - Multiple discounts

    func testMultipleDiscounts() {
        let dict: [AnyHashable: Any] = [
            "line_item_group": [
                "discount_amounts": [
                    [
                        "amount": 500,
                        "coupon": [
                            "name": "First",
                            "percent_off": 10.0,
                        ] as [String: Any],
                        "promotion_code": [
                            "code": "FIRST10",
                        ],
                    ] as [String: Any],
                    [
                        "amount": 200,
                        "coupon": [
                            "name": "Second",
                            "amount_off": 200,
                        ] as [String: Any],
                    ] as [String: Any],
                ],
            ],
        ]

        let discounts = STPCheckoutSessionDiscount.discounts(from: dict)
        XCTAssertEqual(discounts.count, 2)

        XCTAssertEqual(discounts[0].id, "discount_0")
        XCTAssertEqual(discounts[0].name, "First")
        XCTAssertEqual(discounts[0].promotionCode?.code, "FIRST10")
        XCTAssertEqual(discounts[0].amount, 500)
        XCTAssertEqual(discounts[0].percentOff, 10.0)

        XCTAssertEqual(discounts[1].id, "discount_1")
        XCTAssertEqual(discounts[1].name, "Second")
        XCTAssertNil(discounts[1].promotionCode)
        XCTAssertEqual(discounts[1].amount, 200)
        XCTAssertEqual(discounts[1].amountOff, 200)
    }

    // MARK: - Zero amount mixed with valid discounts

    func testZeroAmountFilteredFromMultipleDiscounts() {
        let dict: [AnyHashable: Any] = [
            "line_item_group": [
                "discount_amounts": [
                    [
                        "amount": 0,
                        "coupon": ["name": "Zero"] as [String: Any],
                    ] as [String: Any],
                    [
                        "amount": 300,
                        "coupon": ["name": "Valid"] as [String: Any],
                    ] as [String: Any],
                ],
            ],
        ]

        let discounts = STPCheckoutSessionDiscount.discounts(from: dict)
        XCTAssertEqual(discounts.count, 1)
        // The zero-amount entry at index 0 is filtered, but the ID uses the original index
        XCTAssertEqual(discounts[0].id, "discount_1")
        XCTAssertEqual(discounts[0].name, "Valid")
        XCTAssertEqual(discounts[0].amount, 300)
    }

    // MARK: - Missing coupon key

    func testDiscountWithNoCoupon() {
        let dict: [AnyHashable: Any] = [
            "line_item_group": [
                "discount_amounts": [
                    [
                        "amount": 100,
                    ] as [String: Any],
                ],
            ],
        ]

        let discounts = STPCheckoutSessionDiscount.discounts(from: dict)
        XCTAssertEqual(discounts.count, 1)
        XCTAssertNil(discounts[0].name)
        XCTAssertNil(discounts[0].percentOff)
        XCTAssertNil(discounts[0].amountOff)
    }
}
