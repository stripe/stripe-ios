//
//  VerticalPaymentMethodListViewControllerSnapshotTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 5/9/24.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) import StripeUICore
import XCTest

final class VerticalPaymentMethodListViewControllerSnapshotTest: STPSnapshotTestCase, VerticalPaymentMethodListViewControllerDelegate {
    func shouldSelectPaymentMethod(_ selection: StripePaymentSheet.VerticalPaymentMethodListSelection) -> Bool {
        return true
    }

    func didTapPaymentMethod(_ selection: StripePaymentSheet.VerticalPaymentMethodListSelection) {

    }

    func didTapSavedPaymentMethodAccessoryButton() {

    }

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
    
    override func setUp() {
        super.setUp()
        DownloadManager.sharedManager.resetCache()
    }

    func testNoSavedPM_noApplePayLink() {
        let sut = VerticalPaymentMethodListViewController(initialSelection: nil, savedPaymentMethod: nil, paymentMethodTypes: paymentMethods.map { .stripe($0) }, shouldShowApplePay: false, shouldShowLink: false, savedPaymentMethodAccessoryType: .edit, overrideHeaderView: nil, appearance: .default, currency: "USD", amount: 1099, incentive: nil, delegate: self)
        STPSnapshotVerifyView(sut.view, autoSizingHeightForWidth: 375)
    }

    func testSavedCard_noApplePayLink() {
        let sut = VerticalPaymentMethodListViewController(initialSelection: .saved(paymentMethod: ._testCard()), savedPaymentMethod: ._testCard(), paymentMethodTypes: paymentMethods.map { .stripe($0) }, shouldShowApplePay: false, shouldShowLink: false, savedPaymentMethodAccessoryType: .edit, overrideHeaderView: nil, appearance: .default, currency: "USD", amount: 1099, incentive: nil, delegate: self)
        STPSnapshotVerifyView(sut.view, autoSizingHeightForWidth: 375)
    }

    func testSavedCard_ApplePayLink() {
        let sut = VerticalPaymentMethodListViewController(initialSelection: .saved(paymentMethod: ._testCard()), savedPaymentMethod: ._testCard(), paymentMethodTypes: paymentMethods.map { .stripe($0) }, shouldShowApplePay: true, shouldShowLink: true, savedPaymentMethodAccessoryType: .edit, overrideHeaderView: nil, appearance: .default, currency: "USD", amount: 1099, incentive: nil, delegate: self)
        STPSnapshotVerifyView(sut.view, autoSizingHeightForWidth: 375)
    }

    func testDarkMode() {
        let sut = VerticalPaymentMethodListViewController(initialSelection: .saved(paymentMethod: ._testCard()), savedPaymentMethod: ._testCard(), paymentMethodTypes: paymentMethods.map { .stripe($0) }, shouldShowApplePay: true, shouldShowLink: true, savedPaymentMethodAccessoryType: .edit, overrideHeaderView: nil, appearance: .default, currency: "USD", amount: 1099, incentive: nil, delegate: self)
        let window = UIWindow()
        window.isHidden = false
        window.addAndPinSubview(sut.view, insets: .zero)
        window.overrideUserInterfaceStyle = .dark
        STPSnapshotVerifyView(window, autoSizingHeightForWidth: 375)
    }

    func testAppearance() {
        let sut = VerticalPaymentMethodListViewController(initialSelection: .saved(paymentMethod: ._testCard()), savedPaymentMethod: ._testCard(), paymentMethodTypes: paymentMethods.map { .stripe($0) }, shouldShowApplePay: true, shouldShowLink: true, savedPaymentMethodAccessoryType: .edit, overrideHeaderView: nil, appearance: ._testMSPaintTheme, currency: "USD", amount: 1099, incentive: nil, delegate: self)
        let window = UIWindow()
        window.isHidden = false
        window.addAndPinSubview(sut.view, insets: .zero)
        STPSnapshotVerifyView(window, autoSizingHeightForWidth: 375)
    }
}
