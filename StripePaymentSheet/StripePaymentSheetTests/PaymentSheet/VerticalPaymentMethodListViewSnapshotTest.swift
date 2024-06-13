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
        let sut = VerticalPaymentMethodListView(initialSelection: nil, savedPaymentMethod: nil, paymentMethodTypes: paymentMethods.map { .stripe($0) }, shouldShowApplePay: false, shouldShowLink: false, savedPaymentMethodAccessoryType: .edit, overrideHeaderView: nil, appearance: .default, currency: "USD", amount: 1099)
        STPSnapshotVerifyView(sut, autoSizingHeightForWidth: 375)
    }

    func testSavedCard_noApplePayLink() {
        let sut = VerticalPaymentMethodListView(initialSelection: .saved(paymentMethod: ._testCard()), savedPaymentMethod: ._testCard(), paymentMethodTypes: paymentMethods.map { .stripe($0) }, shouldShowApplePay: false, shouldShowLink: false, savedPaymentMethodAccessoryType: .edit, overrideHeaderView: nil, appearance: .default, currency: "USD", amount: 1099)
        STPSnapshotVerifyView(sut, autoSizingHeightForWidth: 375)
    }

    func testSavedCard_ApplePayLink() {
        let sut = VerticalPaymentMethodListView(initialSelection: .saved(paymentMethod: ._testCard()), savedPaymentMethod: ._testCard(), paymentMethodTypes: paymentMethods.map { .stripe($0) }, shouldShowApplePay: true, shouldShowLink: true, savedPaymentMethodAccessoryType: .edit, overrideHeaderView: nil, appearance: .default, currency: "USD", amount: 1099)
        STPSnapshotVerifyView(sut, autoSizingHeightForWidth: 375)
    }

    func testDarkMode() {
        let sut = VerticalPaymentMethodListView(initialSelection: .saved(paymentMethod: ._testCard()), savedPaymentMethod: ._testCard(), paymentMethodTypes: paymentMethods.map { .stripe($0) }, shouldShowApplePay: true, shouldShowLink: true, savedPaymentMethodAccessoryType: .edit, overrideHeaderView: nil, appearance: .default, currency: "USD", amount: 1099)
        let window = UIWindow()
        window.isHidden = false
        window.addAndPinSubview(sut, insets: .zero)
        window.overrideUserInterfaceStyle = .dark
        STPSnapshotVerifyView(window, autoSizingHeightForWidth: 375)
    }

    func testAppearance() {
        let sut = VerticalPaymentMethodListView(initialSelection: .saved(paymentMethod: ._testCard()), savedPaymentMethod: ._testCard(), paymentMethodTypes: paymentMethods.map { .stripe($0) }, shouldShowApplePay: true, shouldShowLink: true, savedPaymentMethodAccessoryType: .edit, overrideHeaderView: nil, appearance: ._testMSPaintTheme, currency: "USD", amount: 1099)
        let window = UIWindow()
        window.isHidden = false
        window.addAndPinSubview(sut, insets: .zero)
        STPSnapshotVerifyView(window, autoSizingHeightForWidth: 375)
    }
}
