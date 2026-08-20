//
//  PaymentPagesAPIResponseDiscountTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripePaymentSheet
import XCTest

private extension PaymentPagesAPIResponse {
    static func makeDiscounts(from overrides: [String: Any]) -> [CheckoutController.Session.DiscountAmount] {
        return CheckoutTestHelpers.makeSession(overrides).makePublicSession().discountAmounts
    }
}

final class PaymentPagesAPIResponseDiscountTests: XCTestCase {

    // MARK: - Valid discount with coupon + promotion code

    func testParseDiscountWithCouponAndPromotionCode() {
        let dict: [String: Any] = [
            "currency": "usd",
            "recurring_details": [
                "total_discount_amounts": [
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

        let discounts = PaymentPagesAPIResponse.makeDiscounts(from: dict)
        XCTAssertEqual(discounts.count, 1)

        let discount = discounts[0]
        XCTAssertEqual(discount.displayName, "25% Off")
        XCTAssertEqual(discount.promotionCode, "SAVE25")
        XCTAssertEqual(discount.amount, "$5.00")
        XCTAssertEqual(discount.minorUnitsAmount, 500)
        XCTAssertEqual(discount.percentOff, 25)
    }

    // MARK: - Discount with coupon only (no promotion code)

    func testParseDiscountWithCouponOnly() {
        let dict: [String: Any] = [
            "currency": "usd",
            "recurring_details": [
                "total_discount_amounts": [
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

        let discounts = PaymentPagesAPIResponse.makeDiscounts(from: dict)
        XCTAssertEqual(discounts.count, 1)

        let discount = discounts[0]
        XCTAssertEqual(discount.displayName, "$10 Off")
        XCTAssertNil(discount.promotionCode)
        XCTAssertEqual(discount.amount, "$10.00")
        XCTAssertEqual(discount.minorUnitsAmount, 1000)
        XCTAssertNil(discount.percentOff)
    }

    // MARK: - Zero amount is filtered out

    func testZeroAmountDiscountIsFiltered() {
        let dict: [String: Any] = [
            "recurring_details": [
                "total_discount_amounts": [
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

        let discounts = PaymentPagesAPIResponse.makeDiscounts(from: dict)
        XCTAssertTrue(discounts.isEmpty)
    }

    // MARK: - Empty discount_amounts array

    func testEmptyDiscountAmountsArray() {
        let dict: [String: Any] = [
            "recurring_details": [
                "total_discount_amounts": [] as [[AnyHashable: Any]],
            ],
        ]

        let discounts = PaymentPagesAPIResponse.makeDiscounts(from: dict)
        XCTAssertTrue(discounts.isEmpty)
    }

    // MARK: - Missing recurring_details key

    func testMissingRecurringDetails() {
        let dict: [String: Any] = [
            "session_id": "cs_test_123",
        ]

        let discounts = PaymentPagesAPIResponse.makeDiscounts(from: dict)
        XCTAssertTrue(discounts.isEmpty)
    }

    // MARK: - Multiple discounts

    func testMultipleDiscounts() {
        let dict: [String: Any] = [
            "currency": "usd",
            "recurring_details": [
                "total_discount_amounts": [
                    [
                        "amount": 500,
                        "coupon": [
                            "id": "coupon_first",
                            "name": "First",
                            "percent_off": 10.5,
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

        let discounts = PaymentPagesAPIResponse.makeDiscounts(from: dict)
        XCTAssertEqual(discounts.count, 2)

        XCTAssertEqual(discounts[0].displayName, "First")
        XCTAssertEqual(discounts[0].promotionCode, "FIRST10")
        XCTAssertEqual(discounts[0].amount, "$5.00")
        XCTAssertEqual(discounts[0].minorUnitsAmount, 500)
        XCTAssertEqual(discounts[0].percentOff, 10.5)

        XCTAssertEqual(discounts[1].displayName, "Second")
        XCTAssertNil(discounts[1].promotionCode)
        XCTAssertEqual(discounts[1].amount, "$2.00")
        XCTAssertEqual(discounts[1].minorUnitsAmount, 200)
        XCTAssertNil(discounts[1].percentOff)
    }

    // MARK: - Zero amount mixed with valid discounts

    func testZeroAmountFilteredFromMultipleDiscounts() {
        let dict: [String: Any] = [
            "currency": "usd",
            "recurring_details": [
                "total_discount_amounts": [
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

        let discounts = PaymentPagesAPIResponse.makeDiscounts(from: dict)
        XCTAssertEqual(discounts.count, 1)
        XCTAssertEqual(discounts[0].displayName, "Valid")
        XCTAssertEqual(discounts[0].minorUnitsAmount, 300)
    }

    // MARK: - Missing coupon key (fallback display name)

    func testDiscountWithNoCoupon() {
        let dict: [String: Any] = [
            "currency": "usd",
            "recurring_details": [
                "total_discount_amounts": [
                    [
                        "amount": 100,
                    ] as [String: Any],
                ],
            ],
        ]

        let discounts = PaymentPagesAPIResponse.makeDiscounts(from: dict)
        XCTAssertEqual(discounts.count, 1)
        XCTAssertEqual(discounts[0].displayName, "Discount")
    }

    // MARK: - Coupon without name uses ID then default

    func testCouponWithoutNameFallsBackToId() {
        let dict: [String: Any] = [
            "currency": "usd",
            "recurring_details": [
                "total_discount_amounts": [
                    [
                        "amount": 250,
                        "coupon": [
                            "id": "coupon_no_id",
                            "percent_off": 5.0,
                        ] as [String: Any],
                    ] as [String: Any],
                ],
            ],
        ]

        let discounts = PaymentPagesAPIResponse.makeDiscounts(from: dict)
        XCTAssertEqual(discounts.count, 1)
        XCTAssertEqual(discounts[0].displayName, "coupon_no_id")
        XCTAssertEqual(discounts[0].percentOff, 5)
    }
}
