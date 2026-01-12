//
//  PaymentSheetImageLibraryTest.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripeUICore
import XCTest

final class PaymentSheetImageLibraryTest: XCTestCase {

    static let cardBrands: [STPCardBrand] = [
        .amex,
        .cartesBancaires,
        .dinersClub,
        .discover,
        .JCB,
        .mastercard,
        .unionPay,
        .unknown,
        .visa,
    ]

    func testCardBrandImageForAllBrands() {
        for brand in Self.cardBrands {
            let image = PaymentSheetImageLibrary.cardBrandImage(for: brand)
            XCTAssert(image.size != .zero, "Missing image for card brand: \(brand)")
        }
    }

    func testCardBrandImageReturnsCorrectImages() {
        XCTAssertEqual(
            PaymentSheetImageLibrary.cardBrandImage(for: .visa).pngData(),
            PaymentSheetImageLibrary.safeImageNamed("ps_card_visa").pngData()
        )
        XCTAssertEqual(
            PaymentSheetImageLibrary.cardBrandImage(for: .amex).pngData(),
            PaymentSheetImageLibrary.safeImageNamed("ps_card_amex").pngData()
        )
        XCTAssertEqual(
            PaymentSheetImageLibrary.cardBrandImage(for: .mastercard).pngData(),
            PaymentSheetImageLibrary.safeImageNamed("ps_card_mastercard").pngData()
        )
        XCTAssertEqual(
            PaymentSheetImageLibrary.cardBrandImage(for: .discover).pngData(),
            PaymentSheetImageLibrary.safeImageNamed("ps_card_discover").pngData()
        )
        XCTAssertEqual(
            PaymentSheetImageLibrary.cardBrandImage(for: .JCB).pngData(),
            PaymentSheetImageLibrary.safeImageNamed("ps_card_jcb").pngData()
        )
        XCTAssertEqual(
            PaymentSheetImageLibrary.cardBrandImage(for: .dinersClub).pngData(),
            PaymentSheetImageLibrary.safeImageNamed("ps_card_diners").pngData()
        )
        XCTAssertEqual(
            PaymentSheetImageLibrary.cardBrandImage(for: .unionPay).pngData(),
            PaymentSheetImageLibrary.safeImageNamed("ps_card_unionpay").pngData()
        )
        XCTAssertEqual(
            PaymentSheetImageLibrary.cardBrandImage(for: .cartesBancaires).pngData(),
            PaymentSheetImageLibrary.safeImageNamed("ps_card_cartes_bancaires").pngData()
        )
        XCTAssertEqual(
            PaymentSheetImageLibrary.cardBrandImage(for: .unknown).pngData(),
            PaymentSheetImageLibrary.safeImageNamed("ps_card_unknown").pngData()
        )
    }

    func testUnpaddedCardBrandImageForAllBrands() {
        for brand in STPCardBrand.allCases {
            let image = PaymentSheetImageLibrary.unpaddedCardBrandImage(for: brand)
            XCTAssert(image.size != .zero, "Missing unpadded image for card brand: \(brand)")
        }
    }

    func testUnpaddedCardBrandImageReturnsCorrectImages() {
        XCTAssertEqual(
            PaymentSheetImageLibrary.unpaddedCardBrandImage(for: .visa).pngData(),
            PaymentSheetImageLibrary.safeImageNamed("ps_card_unpadded_visa").pngData()
        )
        XCTAssertEqual(
            PaymentSheetImageLibrary.unpaddedCardBrandImage(for: .amex).pngData(),
            PaymentSheetImageLibrary.safeImageNamed("ps_card_unpadded_amex").pngData()
        )
        XCTAssertEqual(
            PaymentSheetImageLibrary.unpaddedCardBrandImage(for: .mastercard).pngData(),
            PaymentSheetImageLibrary.safeImageNamed("ps_card_unpadded_mastercard").pngData()
        )
        XCTAssertEqual(
            PaymentSheetImageLibrary.unpaddedCardBrandImage(for: .discover).pngData(),
            PaymentSheetImageLibrary.safeImageNamed("ps_card_unpadded_discover").pngData()
        )
        XCTAssertEqual(
            PaymentSheetImageLibrary.unpaddedCardBrandImage(for: .JCB).pngData(),
            PaymentSheetImageLibrary.safeImageNamed("ps_card_unpadded_jcb").pngData()
        )
        XCTAssertEqual(
            PaymentSheetImageLibrary.unpaddedCardBrandImage(for: .dinersClub).pngData(),
            PaymentSheetImageLibrary.safeImageNamed("ps_card_unpadded_diners_club").pngData()
        )
        XCTAssertEqual(
            PaymentSheetImageLibrary.unpaddedCardBrandImage(for: .unionPay).pngData(),
            PaymentSheetImageLibrary.safeImageNamed("ps_card_unpadded_unionpay").pngData()
        )
        XCTAssertEqual(
            PaymentSheetImageLibrary.unpaddedCardBrandImage(for: .cartesBancaires).pngData(),
            PaymentSheetImageLibrary.safeImageNamed("ps_card_unpadded_cartes_bancaires").pngData()
        )
        // Unknown brand should fall back to padded card brand image
        XCTAssertEqual(
            PaymentSheetImageLibrary.unpaddedCardBrandImage(for: .unknown).pngData(),
            PaymentSheetImageLibrary.cardBrandImage(for: .unknown).pngData()
        )
    }

    func testCVCImageForCardBrand() {
        for brand in Self.cardBrands {
            let image = PaymentSheetImageLibrary.cvcImage(for: brand)

            switch brand {
            case .amex:
                XCTAssertEqual(
                    image.pngData(),
                    PaymentSheetImageLibrary.safeImageNamed("ps_card_cvc_amex").pngData()
                )
            default:
                XCTAssertEqual(
                    image.pngData(),
                    PaymentSheetImageLibrary.safeImageNamed("ps_card_cvc").pngData()
                )
            }
        }
    }

    func testUnknownCardCardImage() {
        XCTAssertEqual(
            PaymentSheetImageLibrary.unknownCardCardImage().pngData(),
            PaymentSheetImageLibrary.cardBrandImage(for: .unknown).pngData()
        )
    }
}
