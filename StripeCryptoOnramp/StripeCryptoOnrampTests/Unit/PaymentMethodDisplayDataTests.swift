//
//  PaymentMethodDisplayDataTests.swift
//  StripeCryptoOnrampTests
//

@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@testable @_spi(CryptoOnrampAlpha) import StripeCryptoOnramp
import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import UIKit
import XCTest

final class PaymentMethodDisplayDataTests: XCTestCase {
    func testLegacyInitializerAndCompletedPatternRemainCompatible() {
        let initializer: (PaymentMethodDisplayData.PaymentMethodType, UIImage, String, String?) -> PaymentMethodDisplayData = PaymentMethodDisplayData.init
        let displayData = initializer(.card, UIImage(), "Link", "Test card")
        let result = CollectPaymentMethodResult.completed(displayData: displayData, kycInfo: nil)
        guard case .completed(let legacyDisplayData, let kycInfo) = result else {
            return XCTFail("Expected completed collection")
        }
        XCTAssertEqual(legacyDisplayData.label, "Link")
        XCTAssertNil(kycInfo)
        XCTAssertNil(legacyDisplayData.cardDetails)
        XCTAssertNil(legacyDisplayData.bankAccountDetails)
        XCTAssertNil(result.cardDetails)
        XCTAssertNil(result.bankAccountDetails)
    }

    func testCanceledResultHasNoDetails() {
        let result = CollectPaymentMethodResult.canceled
        XCTAssertNil(result.displayData)
        XCTAssertNil(result.cardDetails)
        XCTAssertNil(result.bankAccountDetails)
    }

    @MainActor
    func testLinkCardMappingAndResultAccessors() {
        for funding in [STPCardFundingType.debit, .credit, .prepaid, .other] {
            let preview = LinkController.PaymentMethodPreview(
                paymentMethodType: .card, icon: UIImage(), label: "Link", sublabel: "Card",
                instrumentDetails: .card(funding: funding, brand: .visa, last4: "4242")
            )
            let displayData = PaymentMethodDisplayData(linkPreview: preview)
            let result = CollectPaymentMethodResult.completed(displayData: displayData, kycInfo: nil)
            XCTAssertEqual(result.cardDetails?.funding, funding)
            XCTAssertEqual(result.cardDetails?.brand, .visa)
            XCTAssertEqual(result.cardDetails?.last4, "4242")
            XCTAssertEqual(result.cardDetails?.funding, displayData.cardDetails?.funding)
            XCTAssertEqual(result.cardDetails?.brand, displayData.cardDetails?.brand)
            XCTAssertEqual(result.cardDetails?.last4, displayData.cardDetails?.last4)
            XCTAssertNil(result.bankAccountDetails)
            XCTAssertNil(displayData.bankAccountDetails)
            XCTAssertEqual(displayData.paymentMethodType, .card)
            XCTAssertTrue(displayData.icon === preview.icon)
            XCTAssertEqual(displayData.label, preview.label)
            XCTAssertEqual(displayData.sublabel, preview.sublabel)
        }
    }

    @MainActor
    func testLinkBankMappingAndMissingMetadata() {
        let bankPreview = LinkController.PaymentMethodPreview(
            paymentMethodType: .bankAccount, icon: UIImage(), label: "Link", sublabel: "Bank",
            instrumentDetails: .bankAccount(last4: "6789")
        )
        let bank = CollectPaymentMethodResult.completed(displayData: PaymentMethodDisplayData(linkPreview: bankPreview), kycInfo: nil)
        XCTAssertNil(bank.cardDetails)
        XCTAssertEqual(bank.bankAccountDetails?.last4, "6789")
        XCTAssertEqual(bank.bankAccountDetails?.last4, bank.displayData?.bankAccountDetails?.last4)
        XCTAssertEqual(bank.displayData?.paymentMethodType, .bankAccount)

        let genericPreview = LinkController.PaymentMethodPreview(paymentMethodType: .card, icon: UIImage(), label: "Link", sublabel: nil)
        let generic = PaymentMethodDisplayData(linkPreview: genericPreview)
        XCTAssertNil(generic.cardDetails)
        XCTAssertNil(generic.bankAccountDetails)
    }

    func testApplePayFundingMapping() throws {
        let cases: [(String?, STPCardFundingType)] = [
            ("debit", .debit), ("credit", .credit), ("prepaid", .prepaid),
            ("unknown", .other), ("unrecognized", .other), (nil, .other),
        ]
        for (funding, expected) in cases {
            let details = try XCTUnwrap(OnrampCardDetails(card: applePayCard(funding: funding)))
            XCTAssertEqual(details.funding, expected)
            XCTAssertEqual(details.brand, .visa)
            XCTAssertEqual(details.last4, "4242")
        }
    }

    func testApplePayMissingCardAndUnknownBrand() throws {
        XCTAssertNil(OnrampCardDetails(card: nil))
        for brand in ["unknown", "unrecognized"] {
            let details = try XCTUnwrap(OnrampCardDetails(card: applePayCard(brand: brand, last4: nil)))
            XCTAssertEqual(details.brand, .unknown)
            XCTAssertNil(details.last4)
        }
    }

    private func applePayCard(funding: String? = "debit", brand: String = "visa", last4: String? = "4242") throws -> StripeAPI.PaymentMethod.Card {
        var fields: [String: Any] = ["exp_month": 12, "exp_year": 2099]
        fields["funding"] = funding
        fields["brand"] = brand
        fields["last4"] = last4
        return try StripeJSONDecoder().decode(StripeAPI.PaymentMethod.Card.self, from: JSONSerialization.data(withJSONObject: fields))
    }
}
