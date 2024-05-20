//
//  VerticalPaymentMethodListViewSnapshotTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 5/9/24.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) import StripeUICore
import XCTest

final class VerticalPaymentMethodListViewSnapshotTest: STPSnapshotTestCase {

    // A list of PMs that have hardcoded image assets
    let paymentMethods: [STPPaymentMethodType] = [
        .afterpayClearpay,
        .alipay,
        .AUBECSDebit,
        .bancontact,
        .USBankAccount,
        .blik,
        .boleto,
        .cashApp,
        .card,
        .EPS,
        .giropay,
        .iDEAL,
        .klarna,
        .konbini,
        .OXXO,
        .przelewy24,
        .payPal,
        .revolutPay,
        .SEPADebit,
        .swish,
        .UPI,
    ]

    func testNoSavedPM_noApplePayLink() {
        let sut = VerticalPaymentMethodListView(savedPaymentMethod: nil, paymentMethodTypes: paymentMethods.map { .stripe($0) }, shouldShowApplePay: false, shouldShowLink: false, appearance: .default)
        STPSnapshotVerifyView(sut, autoSizingHeightForWidth: 375)
    }

    func testSavedCard_noApplePayLink() {
        let sut = VerticalPaymentMethodListView(savedPaymentMethod: ._testCard(), paymentMethodTypes: paymentMethods.map { .stripe($0) }, shouldShowApplePay: false, shouldShowLink: false, appearance: .default)
        STPSnapshotVerifyView(sut, autoSizingHeightForWidth: 375)
    }

    func testSavedCard_ApplePayLink() {
        let sut = VerticalPaymentMethodListView(savedPaymentMethod: ._testCard(), paymentMethodTypes: paymentMethods.map { .stripe($0) }, shouldShowApplePay: true, shouldShowLink: true, appearance: .default)
        STPSnapshotVerifyView(sut, autoSizingHeightForWidth: 375)
    }

    func testDarkMode() {
        let sut = VerticalPaymentMethodListView(savedPaymentMethod: ._testCard(), paymentMethodTypes: paymentMethods.map { .stripe($0) }, shouldShowApplePay: true, shouldShowLink: true, appearance: .default)
        let window = UIWindow()
        window.isHidden = false
        window.addAndPinSubview(sut, insets: .zero)
        window.overrideUserInterfaceStyle = .dark
        STPSnapshotVerifyView(window, autoSizingHeightForWidth: 375)
    }

    func testAppearance() {
        let sut = VerticalPaymentMethodListView(savedPaymentMethod: ._testCard(), paymentMethodTypes: paymentMethods.map { .stripe($0) }, shouldShowApplePay: true, shouldShowLink: true, appearance: ._testMSPaintTheme)
        let window = UIWindow()
        window.isHidden = false
        window.addAndPinSubview(sut, insets: .zero)
        STPSnapshotVerifyView(window, autoSizingHeightForWidth: 375)
    }
}
