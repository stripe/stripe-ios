//
//  STPImageLibraryTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 4/7/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(ReactNativeSDK) @_spi(AppearanceAPIAdditionsPreview) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
@testable@_spi(STP) import StripeUICore

class STPImageLibraryTests: XCTestCase {

    static let cardBrands: [STPCardBrand] = [
        .amex,
        .cartesBancaires,
        .dinersClub,
        .discover,
        .JCB,
        .jaywan,
        .mastercard,
        .unionPay,
        .unknown,
        .visa,
    ]

    func testCardIconMethods() {
        STPAssertEqualImages(
            STPImageLibrary.amexCardImage(),
            STPImageLibrary.safeImageNamed("stp_card_amex", templateIfAvailable: false)
        )
        STPAssertEqualImages(
            STPImageLibrary.dinersClubCardImage(),
            STPImageLibrary.safeImageNamed("stp_card_diners", templateIfAvailable: false)
        )
        STPAssertEqualImages(
            STPImageLibrary.discoverCardImage(),
            STPImageLibrary.safeImageNamed("stp_card_discover", templateIfAvailable: false)
        )
        STPAssertEqualImages(
            STPImageLibrary.jcbCardImage(),
            STPImageLibrary.safeImageNamed("stp_card_jcb", templateIfAvailable: false)
        )
        STPAssertEqualImages(
            STPImageLibrary.mastercardCardImage(),
            STPImageLibrary.safeImageNamed("stp_card_mastercard", templateIfAvailable: false)
        )
        STPAssertEqualImages(
            STPImageLibrary.unionPayCardImage(),
            STPImageLibrary.safeImageNamed("stp_card_unionpay", templateIfAvailable: false)
        )
        STPAssertEqualImages(
            STPImageLibrary.visaCardImage(),
            STPImageLibrary.safeImageNamed("stp_card_visa", templateIfAvailable: false)
        )
        STPAssertEqualImages(
            STPImageLibrary.unknownCardCardImage(),
            STPImageLibrary.safeImageNamed("stp_card_unknown", templateIfAvailable: false)
        )
    }

    func testBrandImageForCardBrand() {
        for brand in Self.cardBrands {
            let image = STPImageLibrary.brandImage(for: brand, template: false)

            switch brand {
            case .visa:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed("stp_card_visa", templateIfAvailable: false)
                )
            case .amex:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed("stp_card_amex", templateIfAvailable: false)
                )
            case .mastercard:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed(
                        "stp_card_mastercard",
                        templateIfAvailable: false
                    )
                )
            case .discover:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed("stp_card_discover", templateIfAvailable: false)
                )
            case .JCB:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed("stp_card_jcb", templateIfAvailable: false)
                )
            case .dinersClub:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed("stp_card_diners", templateIfAvailable: false)
                )
            case .unionPay:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed("stp_card_unionpay", templateIfAvailable: false)
                )
            case .cartesBancaires:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed("stp_card_cartes_bancaires", templateIfAvailable: false)
                )
            case .jaywan:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed("stp_card_jaywan", templateIfAvailable: false)
                )
            case .unknown:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed("stp_card_unknown", templateIfAvailable: false)
                )
            }
        }
    }

    func testUnpaddedImageForCardBrands() {
        for brand in STPCardBrand.allCases {
            let image = STPImageLibrary.unpaddedCardBrandImage(for: brand)
            // Assert image exists
            XCTAssert(image.size != .zero)
        }
    }

    func testTemplatedImageForCardBrands() {
        for brand in STPCardBrand.allCases {
            let image = STPImageLibrary.templatedBrandImage(for: brand)
            // Assert image exists
            XCTAssert(image.size != .zero, "Missing templated image for \(brand)")
        }
    }

    func testJaywanImages() {
        // Given the Jaywan card brand icon
        let jaywanImage = STPImageLibrary.safeImageNamed("stp_card_jaywan", templateIfAvailable: false)
        // Then it is bundled, and has the same size as the other card brand icons
        XCTAssertEqual(jaywanImage.size, STPImageLibrary.safeImageNamed("stp_card_visa", templateIfAvailable: false).size)

        // ...and it's used for the Jaywan card brand image
        STPAssertEqualImages(STPImageLibrary.cardBrandImage(for: .jaywan), jaywanImage)

        // When requesting the templated or unpadded variants, which have no Jaywan-specific artwork yet
        let templatedImage = STPImageLibrary.templatedBrandImage(for: .jaywan)
        let unpaddedImage = STPImageLibrary.unpaddedCardBrandImage(for: .jaywan)
        // Then the full-color icon is used and is never tinted
        STPAssertEqualImages(templatedImage, jaywanImage)
        XCTAssertEqual(templatedImage.renderingMode, .alwaysOriginal)
        STPAssertEqualImages(unpaddedImage, jaywanImage)
        XCTAssertNotEqual(unpaddedImage.renderingMode, .alwaysTemplate)
    }

    func testSavedPaymentMethodCellImageForCardBrands() {
        for brand in STPCardBrand.allCases {
            for style in [UIUserInterfaceStyle.light, .dark] {
                let image = brand.makeSavedPaymentMethodCellImage(overrideUserInterfaceStyle: style)
                XCTAssert(image.size != .zero, "Missing saved payment method cell image for \(brand)")
                XCTAssertEqual(image.renderingMode, .alwaysOriginal)
            }
        }
    }

    func testCVCImageForCardBrand() {
        for brand in Self.cardBrands {
            let image = STPImageLibrary.cvcImage(for: brand)

            switch brand {
            case .amex:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed("stp_card_cvc_amex", templateIfAvailable: false)
                )
            default:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed("stp_card_cvc", templateIfAvailable: false)
                )
            }
        }
    }

    func testErrorImageForCardBrand() {
        for brand in Self.cardBrands {
            let image = STPImageLibrary.errorImage(for: brand)
            STPAssertEqualImages(
                image,
                STPImageLibrary.safeImageNamed("stp_card_error", templateIfAvailable: false)
            )
        }
    }

    func testBankIconCodeImagesExist() {
        for iconCode in PaymentSheetImageLibrary.BankIconCodeRegexes.keys {
            XCTAssertNotNil(
                PaymentSheetImageLibrary.bankIcon(for: iconCode, iconStyle: .filled),
                "Missing image for \(iconCode)"
            )
        }
    }

    func testBankNameToIconCode() {
        // bank of america
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "bank of america"), "boa")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "BANK of AMERICA"), "boa")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "BANKof AMERICA"), "default")

        // capital one
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "capital one"), "capitalone")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "Capital One"), "capitalone")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "Capital      One"), "default")

        // citibank
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "citibank"), "citibank")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "Citibank"), "citibank")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "Citi Bank"), "default")

        // compass
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "bbva"), "compass")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "BBVA"), "compass")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "compass"), "compass")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "b b v a"), "default")

        // morganchase
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "Morgan Chase"), "morganchase")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "morgan chase"), "morganchase")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "jp morgan"), "morganchase")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "JP Morgan"), "morganchase")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "Chase"), "morganchase")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "chase"), "morganchase")

        // pnc
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "pncbank"), "pnc")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "PNCBANK"), "pnc")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "pnc bank"), "pnc")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "PNC Bank"), "pnc")

        // suntrust
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "suntrust"), "suntrust")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "SUNTRUST"), "suntrust")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "suntrust bank"), "suntrust")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "Suntrust Bank"), "suntrust")

        // svb
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "Silicon Valley Bank"), "svb")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "SILICON VALLEY BANK"), "svb")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "SILICONVALLEYBANK"), "default")

        // usaa
        XCTAssertEqual(
            PaymentSheetImageLibrary.bankIconCode(for: "USAA Federal Savings Bank"),
            "usaa"
        )
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "USAA Bank"), "usaa")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "USAA Savings Bank"), "default")

        // usbank
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "US Bank"), "usbank")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "U.S. Bank"), "usbank")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "u.s. Bank"), "usbank")

        // wellsfargo
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "Wells Fargo"), "wellsfargo")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "WELLS FARGO"), "wellsfargo")
        XCTAssertEqual(PaymentSheetImageLibrary.bankIconCode(for: "Well's Fargo"), "default")
    }

}
