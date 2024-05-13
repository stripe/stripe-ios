//
//  VerticalSavedPaymentMethodsViewControllerSnapshotTests.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/7/24.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
import XCTest

final class VerticalSavedPaymentMethodsViewControllerSnapshotTests: STPSnapshotTestCase {

    func test_VerticalSavedPaymentOptionsViewControllerSnapshotTestsDarkMode() {
        _test_VerticalSavedPaymentMethodsViewControllerSnapshotTests(darkMode: true)
    }

    func test_VerticalSavedPaymentMethodsViewControllerSnapshotTestsLightMode() {
        _test_VerticalSavedPaymentMethodsViewControllerSnapshotTests(darkMode: false)
    }

    func test_VerticalSavedPaymentMethodsViewControllerSnapshotTestsAppearance() {
        _test_VerticalSavedPaymentMethodsViewControllerSnapshotTests(darkMode: false, appearance: ._testMSPaintTheme)
    }

    func _test_VerticalSavedPaymentMethodsViewControllerSnapshotTests(darkMode: Bool, appearance: PaymentSheet.Appearance = .default) {
        var configuration = PaymentSheet.Configuration()
        configuration.appearance = appearance
        let sut = VerticalSavedPaymentMethodsViewController(configuration: configuration, paymentMethods: generatePaymentMethods())
        let bottomSheet = BottomSheetViewController(contentViewController: sut, appearance: appearance, isTestMode: true, didCancelNative3DS2: {})
        bottomSheet.view.autosizeHeight(width: 375)

        let testWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 500))
        testWindow.isHidden = false
        if darkMode {
            testWindow.overrideUserInterfaceStyle = .dark
        }
        testWindow.rootViewController = bottomSheet
        STPSnapshotVerifyView(bottomSheet.view)
    }

    private func generatePaymentMethods() -> [STPPaymentMethod] {
        return [STPFixtures.paymentMethod(),
                STPFixtures.usBankAccountPaymentMethod(),
                STPFixtures.usBankAccountPaymentMethod(bankName: "BANK OF AMERICA"),
                STPFixtures.usBankAccountPaymentMethod(bankName: "STRIPE"),
                STPFixtures.sepaDebitPaymentMethod(), ]
    }
}
