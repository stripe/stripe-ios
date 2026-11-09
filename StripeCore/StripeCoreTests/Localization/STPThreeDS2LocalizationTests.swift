//
//  STPThreeDS2LocalizationTests.swift
//  StripeCoreTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(InternalOnlyAPI) @testable import StripeCore
import XCTest

final class STPThreeDS2LocalizationTests: XCTestCase {
    override func tearDown() {
        STPLocalizationUtils.overrideLanguage(to: nil)
        super.tearDown()
    }

    func testFrenchChallengeLabels() {
        // Given the merchant uses French.
        STPLocalizationUtils.overrideLanguage(to: "fr")

        // Then the SDK-owned challenge labels come from StripeCore resources.
        XCTAssertEqual(STPThreeDS2Localization.secureCheckout, "Paiement sécurisé")
        XCTAssertEqual(STPThreeDS2Localization.cancel, "Annuler")
        XCTAssertEqual(STPThreeDS2Localization.loading, "Chargement")
        XCTAssertEqual(STPThreeDS2Localization.yes, "Oui")
        XCTAssertEqual(STPThreeDS2Localization.no, "Non")
    }

    func testArabicChallengeLabels() {
        // Given the merchant uses Arabic.
        STPLocalizationUtils.overrideLanguage(to: "ar-SA")

        // Then the SDK-owned challenge labels come from StripeCore resources.
        XCTAssertEqual(STPThreeDS2Localization.secureCheckout, "الدفع الآمن")
        XCTAssertEqual(STPThreeDS2Localization.cancel, "إلغاء")
        XCTAssertEqual(STPThreeDS2Localization.loading, "جارٍ التحميل")
        XCTAssertEqual(STPThreeDS2Localization.yes, "نعم")
        XCTAssertEqual(STPThreeDS2Localization.no, "لا")
    }

    func testThaiChallengeLabels() {
        // Given the merchant uses Thai.
        STPLocalizationUtils.overrideLanguage(to: "th")

        // Then the SDK-owned challenge labels come from StripeCore resources.
        XCTAssertEqual(STPThreeDS2Localization.secureCheckout, "การชำระเงินที่ปลอดภัย")
        XCTAssertEqual(STPThreeDS2Localization.cancel, "ยกเลิก")
        XCTAssertEqual(STPThreeDS2Localization.loading, "กำลังโหลด")
        XCTAssertEqual(STPThreeDS2Localization.yes, "ใช่")
        XCTAssertEqual(STPThreeDS2Localization.no, "ไม่")
    }

    func testWelshChallengeLabels() {
        // Given the merchant uses Welsh.
        STPLocalizationUtils.overrideLanguage(to: "cy-GB")

        // Then the SDK-owned challenge labels come from StripeCore resources.
        XCTAssertEqual(STPThreeDS2Localization.secureCheckout, "Talu’n ddiogel")
        XCTAssertEqual(STPThreeDS2Localization.cancel, "Canslo")
        XCTAssertEqual(STPThreeDS2Localization.loading, "Wrthi’n llwytho")
        XCTAssertEqual(STPThreeDS2Localization.yes, "Ie")
        XCTAssertEqual(STPThreeDS2Localization.no, "Na")
    }
}
