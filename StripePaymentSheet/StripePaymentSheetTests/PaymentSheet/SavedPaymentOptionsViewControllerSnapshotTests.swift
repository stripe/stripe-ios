//
//  SavedPaymentOptionsViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 10/13/23.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
@_spi(STP) @testable import StripeUICore
import XCTest

final class SavedPaymentOptionsViewControllerSnapshotTests: STPSnapshotTestCase {

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
        let config = SavedPaymentOptionsViewController.Configuration(customerID: "cus_123", showApplePay: true, showLink: true, removeSavedPaymentMethodMessage: nil, merchantDisplayName: "Test Merchant", isCVCRecollectionEnabled: false, isTestMode: false, allowsRemovalOfLastSavedPaymentMethod: false, allowsRemovalOfPaymentMethods: true)
        let intent = Intent.deferredIntent(intentConfig: .init(mode: .payment(amount: 0, currency: "USD", setupFutureUsage: nil, captureMethod: .automatic), confirmHandler: { _, _, _ in }))
        let sut = SavedPaymentOptionsViewController(savedPaymentMethods: paymentMethods,
                                                    configuration: config,
                                                    paymentSheetConfiguration: PaymentSheet.Configuration(),
                                                    intent: intent,
                                                    appearance: appearance,
                                                    analyticsHelper: ._testValue())
        let testWindow = UIWindow()
        testWindow.isHidden = false
        if darkMode {
            testWindow.overrideUserInterfaceStyle = .dark
        }
        testWindow.rootViewController = sut
        // Adding sut.view as the subview should be implied by the above line, but Autolayout can't lay out the view correctly on this pass of the runloop unless we explicitly addSubview. Maybe there are side effects that happen one turn of the runloop after setting the rootViewController.
        testWindow.addSubview(sut.view)
        sut.view.autosizeHeight(width: 1000)
        NSLayoutConstraint.activate([
            sut.view.topAnchor.constraint(equalTo: testWindow.topAnchor),
            sut.view.leftAnchor.constraint(equalTo: testWindow.leftAnchor),
        ])
        STPSnapshotVerifyView(sut.view)
    }
}
