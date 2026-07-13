//
//  PaymentSheetTestPlaygroundSettingsTests.swift
//  PaymentSheet Example
//

import XCTest

final class PaymentSheetTestPlaygroundSettingsTests: XCTestCase {
    func testConfirmEndpointUsesHostedBackendByDefault() {
        let settings = PaymentSheetTestPlaygroundSettings.defaultValues()

        XCTAssertEqual(
            settings.confirmEndpoint,
            "https://stp-mobile-playground-backend-v7.stripedemos.com/confirm_intent"
        )
    }

    func testConfirmEndpointFollowsCustomCheckoutEndpoint() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.checkoutEndpoint = "http://127.0.0.1:8081/checkout"

        XCTAssertEqual(
            settings.confirmEndpoint,
            "http://127.0.0.1:8081/confirm_intent"
        )
    }

    func testUsesVippsPreviewForNokAutomaticPaymentMethods() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.currency = .nok
        settings.apmsEnabled = .on

        XCTAssertTrue(settings.usesVippsPreview)
    }

    func testUsesVippsPreviewForExplicitVippsSupportedPaymentMethods() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.supportedPaymentMethods = "card, vipps"

        XCTAssertTrue(settings.usesVippsPreview)
    }

    func testDoesNotUseVippsPreviewForNonVippsSettings() {
        let settings = PaymentSheetTestPlaygroundSettings.defaultValues()

        XCTAssertFalse(settings.usesVippsPreview)
    }
}
