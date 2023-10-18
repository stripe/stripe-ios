//
//  SavedPaymentOptionsViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 10/13/23.
//

import iOSSnapshotTestCase
import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
@_spi(STP) @testable import StripeUICore
import XCTest

final class SavedPaymentOptionsViewControllerSnapshotTests: FBSnapshotTestCase {
    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func test_all_saved_pms_and_apple_pay_and_link_dark() {
        _test_all_saved_pms_and_apple_pay_and_link(darkMode: true)
    }

    func test_all_saved_pms_and_apple_pay_and_link() {
        _test_all_saved_pms_and_apple_pay_and_link(darkMode: false)
    }

    func test_all_saved_pms_and_apple_pay_and_link_custom_appearance() {
        _test_all_saved_pms_and_apple_pay_and_link(darkMode: false, appearance: ._testMSPaintTheme)
    }

    func _test_all_saved_pms_and_apple_pay_and_link(darkMode: Bool, appearance: PaymentSheet.Appearance = .default) {
        let paymentMethods = [
            STPPaymentMethod._testCard(),
            STPPaymentMethod._testUSBankAccount(),
            STPPaymentMethod._testSEPA(),
        ]
        let config = SavedPaymentOptionsViewController.Configuration(customerID: "cus_123", showApplePay: true, showLink: true, removeSavedPaymentMethodMessage: nil, merchantDisplayName: "Test Merchant")
        let sut = SavedPaymentOptionsViewController(savedPaymentMethods: paymentMethods, configuration: config, appearance: appearance)
        let testWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 500))
        testWindow.isHidden = false
        if darkMode {
            testWindow.overrideUserInterfaceStyle = .dark
        }
        testWindow.rootViewController = sut
        sut.view.autosizeHeight(width: 1000)
        STPSnapshotVerifyView(sut.view)
    }
}
