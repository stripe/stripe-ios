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

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
//        self.recordMode = true
    }

    func testNoSavedPM_noApplePayLink() {
        let sut = VerticalPaymentMethodListView(savedPaymentMethod: nil, paymentMethodTypes: paymentMethods.map { .stripe($0) }, shouldShowApplePay: false, shouldShowLink: false, appearance: .default, delegate: self)
        STPSnapshotVerifyView(sut, autoSizingHeightForWidth: 375)
    }

    func testSavedCard_noApplePayLink() {
        let sut = VerticalPaymentMethodListView(savedPaymentMethod: ._testCard(), paymentMethodTypes: paymentMethods.map { .stripe($0) }, shouldShowApplePay: false, shouldShowLink: false, appearance: .default, delegate: self)
        STPSnapshotVerifyView(sut, autoSizingHeightForWidth: 375)
    }

    func testSavedCard_ApplePayLink() {
        let sut = VerticalPaymentMethodListView(savedPaymentMethod: ._testCard(), paymentMethodTypes: paymentMethods.map { .stripe($0) }, shouldShowApplePay: true, shouldShowLink: true, appearance: .default, delegate: self)
        STPSnapshotVerifyView(sut, autoSizingHeightForWidth: 375)
    }

    func testDarkMode() {
        let sut = VerticalPaymentMethodListView(savedPaymentMethod: ._testCard(), paymentMethodTypes: paymentMethods.map { .stripe($0) }, shouldShowApplePay: true, shouldShowLink: true, appearance: .default, delegate: self)
        let window = UIWindow()
        window.isHidden = false
        window.addAndPinSubview(sut, insets: .zero)
        window.overrideUserInterfaceStyle = .dark
        STPSnapshotVerifyView(window, autoSizingHeightForWidth: 375)
    }

    func testAppearance() {
        let sut = VerticalPaymentMethodListView(savedPaymentMethod: ._testCard(), paymentMethodTypes: paymentMethods.map { .stripe($0) }, shouldShowApplePay: true, shouldShowLink: true, appearance: ._testMSPaintTheme, delegate: self)
        let window = UIWindow()
        window.isHidden = false
        window.addAndPinSubview(sut, insets: .zero)
        STPSnapshotVerifyView(window, autoSizingHeightForWidth: 375)
    }
}

extension VerticalPaymentMethodListViewSnapshotTest: VerticalPaymentMethodListViewDelegate {
    func didSelectPaymentMethod(_ selection: StripePaymentSheet.VerticalPaymentMethodListView.Selection) {
        // no-op
    }
}
