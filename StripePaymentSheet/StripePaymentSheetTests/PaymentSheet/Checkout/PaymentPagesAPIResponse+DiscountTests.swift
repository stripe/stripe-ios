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
    override func setUpWithError() throws {
        try super.setUpWithError()
        throw XCTSkip("TODO(porter) promo codes: Restore discount decoding coverage when CheckoutClient supports promotion codes.")
    }

    // MARK: - Valid discount with coupon + promotion code

    func testParseDiscountWithCouponAndPromotionCode() {
        let dict: [String: Any] = [
            "currency": "usd",
            "recurring_details": [
                "total_summary": [
                    "total_discount_amounts": [
                        [
                            "amount": 500,
                            "coupon": [
                                "code": "coupon_abc",
                                "name": "25% Off",
                                "percent_off": 25.0,
                            ] as [String: Any],
                            "promotion_code": [
                                "code": "SAVE25",
                            ],
                        ] as [String: Any],
                    ],
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
                "total_summary": [
                    "total_discount_amounts": [
                        [
                            "amount": 1000,
                            "coupon": [
                                "code": "coupon_def",
                                "name": "$10 Off",
                                "amount_off": 1000,
                            ] as [String: Any],
                        ] as [String: Any],
                    ],
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
                "total_summary": [
                    "total_discount_amounts": [
                        [
                            "amount": 0,
                            "coupon": [
                                "code": "coupon_zero",
                                "name": "No-op",
                            ],
                        ] as [String: Any],
                    ],
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
                "total_summary": [
                    "total_discount_amounts": [] as [[AnyHashable: Any]],
                ],
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
                "total_summary": [
                    "total_discount_amounts": [
                        [
                            "amount": 500,
                            "coupon": [
                                "code": "coupon_first",
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
                                "code": "coupon_second",
                                "name": "Second",
                                "amount_off": 200,
                            ] as [String: Any],
                        ] as [String: Any],
                    ],
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
                "total_summary": [
                    "total_discount_amounts": [
                        [
                            "amount": 0,
                            "coupon": [
                                "code": "coupon_zero",
                                "name": "Zero",
                            ] as [String: Any],
                        ] as [String: Any],
                        [
                            "amount": 300,
                            "coupon": [
                                "code": "coupon_valid",
                                "name": "Valid",
                            ] as [String: Any],
                        ] as [String: Any],
                    ],
                ],
            ],
        ]

        let discounts = PaymentPagesAPIResponse.makeDiscounts(from: dict)
        XCTAssertEqual(discounts.count, 1)
        XCTAssertEqual(discounts[0].displayName, "Valid")
        XCTAssertEqual(discounts[0].minorUnitsAmount, 300)
    }

    // MARK: - Missing required discount fields

    func testDiscountRejectsMissingAmountOrCoupon() {
        let validDiscount: [String: Any] = [
            "amount": 100,
            "coupon": ["code": "coupon_test"],
        ]

        for field in ["amount", "coupon"] {
            var invalidDiscount = validDiscount
            invalidDiscount.removeValue(forKey: field)
            let json = CheckoutTestHelpers.makeSessionJSON([
                "currency": "usd",
                "recurring_details": [
                    "total_summary": [
                        "total_discount_amounts": [invalidDiscount],
                    ],
                ],
            ])

            XCTAssertThrowsError(
                try PaymentPagesAPIResponse.decode(fromAPIResponse: json),
                "Expected missing \(field) to fail decoding"
            )
        }
    }

    func testDiscountRejectsCouponWithoutCode() {
        let json = CheckoutTestHelpers.makeSessionJSON([
            "currency": "usd",
            "recurring_details": [
                "total_summary": [
                    "total_discount_amounts": [
                        [
                            "amount": 100,
                            "coupon": ["name": "Welcome"],
                        ] as [String: Any],
                    ],
                ],
            ],
        ])

        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json))
    }

    // MARK: - Coupon without name uses code

    func testCouponWithoutNameFallsBackToCode() {
        let dict: [String: Any] = [
            "currency": "usd",
            "recurring_details": [
                "total_summary": [
                    "total_discount_amounts": [
                        [
                            "amount": 250,
                            "coupon": [
                                "code": "coupon_no_name",
                                "percent_off": 5.0,
                            ] as [String: Any],
                        ] as [String: Any],
                    ],
                ],
            ],
        ]

        let discounts = PaymentPagesAPIResponse.makeDiscounts(from: dict)
        XCTAssertEqual(discounts.count, 1)
        XCTAssertEqual(discounts[0].displayName, "coupon_no_name")
        XCTAssertEqual(discounts[0].percentOff, 5)
    }

    func testDiscountsUseRecurringTotalSummary() throws {
        // Given different discounts in the recurring summary and deprecated fields
        let recurringDiscount: [String: Any] = [
            "amount": 250,
            "coupon": ["code": "coupon_recurring", "name": "Recurring discount"],
        ]
        let otherDiscount: [String: Any] = [
            "amount": 500,
            "coupon": ["code": "coupon_other", "name": "Other discount"],
        ]
        let json = CheckoutTestHelpers.makeSessionJSON([
            "currency": "usd",
            "recurring_details": [
                "total_discount_amounts": [otherDiscount],
                "total_tax_amounts": "ignored",
                "total_summary": [
                    "total_discount_amounts": [recurringDiscount],
                ],
            ],
            "total_summary": [
                "total_discount_amounts": [otherDiscount],
            ],
        ])

        // When decoding the public session
        let session = try PaymentPagesAPIResponse.decode(fromAPIResponse: json).makePublicSession()

        // Then discounts come from the recurring summary
        XCTAssertEqual(session.discountAmounts.count, 1)
        let discount = try XCTUnwrap(session.discountAmounts.first)
        XCTAssertEqual(discount.minorUnitsAmount, 250)
        XCTAssertEqual(discount.displayName, "Recurring discount")
    }

    func testUnusedSummaryAmountsDoNotAffectDecoding() throws {
        // Given valid discounts and taxes alongside malformed unused summary fields
        let json = CheckoutTestHelpers.makeSessionJSON([
            "recurring_details": [
                "total_summary": [
                    "total_discount_amounts": [
                        ["amount": 250, "coupon": ["code": "coupon_recurring"]],
                    ],
                    "total_tax_amounts": "ignored",
                ],
            ],
            "total_summary": [
                "total_discount_amounts": "ignored",
                "total_tax_amounts": [
                    [
                        "amount": 100,
                        "inclusive": false,
                        "tax_rate": ["display_name": "Sales Tax", "percentage": 10.0],
                    ],
                ],
            ],
        ])

        // When decoding the public session
        let session = try PaymentPagesAPIResponse.decode(fromAPIResponse: json).makePublicSession()

        // Then only the summary fields used by the SDK affect decoding
        XCTAssertEqual(session.discountAmounts.count, 1)
        XCTAssertEqual(session.discountAmounts.first?.minorUnitsAmount, 250)
        XCTAssertEqual(session.taxAmounts?.count, 1)
        XCTAssertEqual(session.taxAmounts?.first?.minorUnitsAmount, 100)
    }

    func testRecurringSummaryRejectsMissingRequiredDiscountAmounts() {
        // Given a recurring summary without a discount array
        let json = CheckoutTestHelpers.makeSessionJSON([
            "recurring_details": ["total_summary": [:]],
        ])

        // Then decoding fails, preserving the required discount array
        XCTAssertThrowsError(try PaymentPagesAPIResponse.decode(fromAPIResponse: json))
    }

    func testRecurringDetailsRejectsMissingRequiredTotalSummary() {
        let json = CheckoutTestHelpers.makeSessionJSON([
            "recurring_details": [:],
        ])

        XCTAssertThrowsError(
            try PaymentPagesAPIResponse.decode(fromAPIResponse: json),
            "Expected missing total_summary to fail decoding"
        )
    }
}
