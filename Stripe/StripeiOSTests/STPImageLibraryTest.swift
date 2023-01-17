//
//  STPImageLibraryTest.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 4/7/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
@testable@_spi(STP) import StripeUICore

class STPImageLibraryTestSwift: XCTestCase {

    static let cardBrands: [STPCardBrand] = [
        .amex,
        .dinersClub,
        .discover,
        .JCB,
        .mastercard,
        .unionPay,
        .unknown,
        .visa,
    ]

    func testCardIconMethods() {
        STPAssertEqualImages(
            STPImageLibrary.applePayCardImage(),
            STPImageLibrary.safeImageNamed("stp_card_applepay", templateIfAvailable: false)
        )
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
            case .unknown:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed("stp_card_unknown", templateIfAvailable: false)
                )
            }
        }
    }

    func testTemplatedBrandImageForCardBrand() {
        for brand in Self.cardBrands {
            let image = STPImageLibrary.templatedBrandImage(for: brand)

            switch brand {
            case .visa:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed(
                        "stp_card_visa_template",
                        templateIfAvailable: true
                    )
                )
            case .amex:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed(
                        "stp_card_amex_template",
                        templateIfAvailable: true
                    )
                )
            case .mastercard:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed(
                        "stp_card_mastercard_template",
                        templateIfAvailable: true
                    )
                )
            case .discover:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed(
                        "stp_card_discover_template",
                        templateIfAvailable: true
                    )
                )
            case .JCB:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed(
                        "stp_card_jcb_template",
                        templateIfAvailable: true
                    )
                )
            case .dinersClub:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed(
                        "stp_card_diners_template",
                        templateIfAvailable: true
                    )
                )
            case .unionPay:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed(
                        "stp_card_unionpay_template",
                        templateIfAvailable: true
                    )
                )
            case .unknown:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed("stp_card_unknown", templateIfAvailable: true)
                )
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

            switch brand {
            case .amex:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed(
                        "stp_card_error_amex",
                        templateIfAvailable: false
                    )
                )
            default:
                STPAssertEqualImages(
                    image,
                    STPImageLibrary.safeImageNamed("stp_card_error", templateIfAvailable: false)
                )
            }
        }
    }

    func testMiscImages() {
        STPAssertEqualImages(
            STPLegacyImageLibrary.addIcon(),
            STPLegacyImageLibrary.safeImageNamed("stp_icon_add", templateIfAvailable: false)
        )
        STPAssertEqualImages(
            STPImageLibrary.bankIcon(),
            STPImageLibrary.safeImageNamed("stp_icon_bank", templateIfAvailable: false)
        )
        STPAssertEqualImages(
            STPLegacyImageLibrary.checkmarkIcon(),
            STPLegacyImageLibrary.safeImageNamed("stp_icon_checkmark", templateIfAvailable: false)
        )
        STPAssertEqualImages(
            STPLegacyImageLibrary.largeCardFrontImage(),
            STPLegacyImageLibrary.safeImageNamed("stp_card_form_front", templateIfAvailable: false)
        )
        STPAssertEqualImages(
            STPLegacyImageLibrary.largeCardBackImage(),
            STPLegacyImageLibrary.safeImageNamed("stp_card_form_back", templateIfAvailable: false)
        )
        STPAssertEqualImages(
            STPLegacyImageLibrary.largeCardAmexCVCImage(),
            STPLegacyImageLibrary.safeImageNamed(
                "stp_card_form_amex_cvc",
                templateIfAvailable: false
            )
        )
        STPAssertEqualImages(
            STPLegacyImageLibrary.largeShippingImage(),
            STPLegacyImageLibrary.safeImageNamed("stp_shipping_form", templateIfAvailable: false)
        )
    }

    func testFPXImages() {
        // Probably better to make STPFPXBankBrand conform to CaseIterable,
        // but let's not change behavior of a legacy product just for this test.
        for i in 0...(STPFPXBankBrand.unknown.rawValue - 1) {
            let brand = STPFPXBankBrand(rawValue: i)!
            let bankIdentifier = STPFPXBank.identifierFrom(brand)!
            let bankImageName = "stp_bank_fpx_" + bankIdentifier
            STPAssertEqualImages(
                STPLegacyImageLibrary.fpxBrandImage(for: brand),
                STPLegacyImageLibrary.safeImageNamed(bankImageName, templateIfAvailable: false)
            )

        }
    }

    func testBankIconCodeImagesExist() {
        for iconCode in PaymentSheetImageLibrary.BankIconCodeRegexes.keys {
            XCTAssertNotNil(
                PaymentSheetImageLibrary.bankIcon(for: iconCode),
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
