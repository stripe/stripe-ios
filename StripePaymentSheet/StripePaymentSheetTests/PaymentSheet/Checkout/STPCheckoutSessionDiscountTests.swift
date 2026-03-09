//
//  STPCheckoutSessionDiscountTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) @_spi(CheckoutSessionsPreview) import StripePaymentSheet
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
                            "id": "coupon_abc",
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

        let discounts = STPCheckoutSession.parseDiscounts(from: dict)
        XCTAssertEqual(discounts.count, 1)

        let discount = discounts[0]
        XCTAssertEqual(discount.coupon.id, "coupon_abc")
        XCTAssertEqual(discount.coupon.name, "25% Off")
        XCTAssertEqual(discount.promotionCode, "SAVE25")
        XCTAssertEqual(discount.amount, 500)
        XCTAssertEqual(discount.coupon.percentOff, 25.0)
        XCTAssertNil(discount.coupon.amountOff)
    }

    // MARK: - Discount with coupon only (no promotion code)

    func testParseDiscountWithCouponOnly() {
        let dict: [AnyHashable: Any] = [
            "line_item_group": [
                "discount_amounts": [
                    [
                        "amount": 1000,
                        "coupon": [
                            "id": "coupon_def",
                            "name": "$10 Off",
                            "amount_off": 1000,
                        ] as [String: Any],
                    ] as [String: Any],
                ],
            ],
        ]

        let discounts = STPCheckoutSession.parseDiscounts(from: dict)
        XCTAssertEqual(discounts.count, 1)

        let discount = discounts[0]
        XCTAssertEqual(discount.coupon.id, "coupon_def")
        XCTAssertEqual(discount.coupon.name, "$10 Off")
        XCTAssertNil(discount.promotionCode)
        XCTAssertEqual(discount.amount, 1000)
        XCTAssertNil(discount.coupon.percentOff)
        XCTAssertEqual(discount.coupon.amountOff, 1000)
    }

    // MARK: - Zero amount is filtered out

    func testZeroAmountDiscountIsFiltered() {
        let dict: [AnyHashable: Any] = [
            "line_item_group": [
                "discount_amounts": [
                    [
                        "amount": 0,
                        "coupon": [
                            "id": "coupon_zero",
                            "name": "No-op",
                        ],
                    ] as [String: Any],
                ],
            ],
        ]

        let discounts = STPCheckoutSession.parseDiscounts(from: dict)
        XCTAssertTrue(discounts.isEmpty)
    }

    // MARK: - Empty discount_amounts array

    func testEmptyDiscountAmountsArray() {
        let dict: [AnyHashable: Any] = [
            "line_item_group": [
                "discount_amounts": [] as [[AnyHashable: Any]],
            ],
        ]

        let discounts = STPCheckoutSession.parseDiscounts(from: dict)
        XCTAssertTrue(discounts.isEmpty)
    }

    // MARK: - Missing line_item_group key

    func testMissingLineItemGroup() {
        let dict: [AnyHashable: Any] = [
            "session_id": "cs_test_123",
        ]

        let discounts = STPCheckoutSession.parseDiscounts(from: dict)
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
                            "id": "coupon_first",
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
                            "id": "coupon_second",
                            "name": "Second",
                            "amount_off": 200,
                        ] as [String: Any],
                    ] as [String: Any],
                ],
            ],
        ]

        let discounts = STPCheckoutSession.parseDiscounts(from: dict)
        XCTAssertEqual(discounts.count, 2)

        XCTAssertEqual(discounts[0].coupon.id, "coupon_first")
        XCTAssertEqual(discounts[0].coupon.name, "First")
        XCTAssertEqual(discounts[0].promotionCode, "FIRST10")
        XCTAssertEqual(discounts[0].amount, 500)
        XCTAssertEqual(discounts[0].coupon.percentOff, 10.0)

        XCTAssertEqual(discounts[1].coupon.id, "coupon_second")
        XCTAssertEqual(discounts[1].coupon.name, "Second")
        XCTAssertNil(discounts[1].promotionCode)
        XCTAssertEqual(discounts[1].amount, 200)
        XCTAssertEqual(discounts[1].coupon.amountOff, 200)
    }

    // MARK: - Zero amount mixed with valid discounts

    func testZeroAmountFilteredFromMultipleDiscounts() {
        let dict: [AnyHashable: Any] = [
            "line_item_group": [
                "discount_amounts": [
                    [
                        "amount": 0,
                        "coupon": [
                            "id": "coupon_zero",
                            "name": "Zero",
                        ] as [String: Any],
                    ] as [String: Any],
                    [
                        "amount": 300,
                        "coupon": [
                            "id": "coupon_valid",
                            "name": "Valid",
                        ] as [String: Any],
                    ] as [String: Any],
                ],
            ],
        ]

        let discounts = STPCheckoutSession.parseDiscounts(from: dict)
        XCTAssertEqual(discounts.count, 1)
        XCTAssertEqual(discounts[0].coupon.id, "coupon_valid")
        XCTAssertEqual(discounts[0].coupon.name, "Valid")
        XCTAssertEqual(discounts[0].amount, 300)
    }

    // MARK: - Missing coupon key (fallback ID)

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

        let discounts = STPCheckoutSession.parseDiscounts(from: dict)
        XCTAssertEqual(discounts.count, 1)
        XCTAssertEqual(discounts[0].coupon.id, "coupon_0")
        XCTAssertNil(discounts[0].coupon.name)
        XCTAssertNil(discounts[0].coupon.percentOff)
        XCTAssertNil(discounts[0].coupon.amountOff)
    }

    // MARK: - Coupon without explicit ID uses fallback

    func testCouponWithoutIdUsesFallback() {
        let dict: [AnyHashable: Any] = [
            "line_item_group": [
                "discount_amounts": [
                    [
                        "amount": 250,
                        "coupon": [
                            "name": "No ID Coupon",
                            "percent_off": 5.0,
                        ] as [String: Any],
                    ] as [String: Any],
                ],
            ],
        ]

        let discounts = STPCheckoutSession.parseDiscounts(from: dict)
        XCTAssertEqual(discounts.count, 1)
        XCTAssertEqual(discounts[0].coupon.id, "coupon_0")
        XCTAssertEqual(discounts[0].coupon.name, "No ID Coupon")
    }
}
