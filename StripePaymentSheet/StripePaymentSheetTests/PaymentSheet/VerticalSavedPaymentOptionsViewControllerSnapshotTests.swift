//
//  VerticalSavedPaymentOptionsViewControllerSnapshotTests.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/7/24.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
import XCTest

final class VerticalSavedPaymentOptionsViewControllerSnapshotTests: STPSnapshotTestCase {

    func test_VerticalSavedPaymentOptionsViewControllerSnapshotTestsDarkMode() {
        _test_VerticalSavedPaymentOptionsViewControllerSnapshotTests(darkMode: true)
    }

    func test_VerticalSavedPaymentOptionsViewControllerSnapshotTestsLightMode() {
        _test_VerticalSavedPaymentOptionsViewControllerSnapshotTests(darkMode: false)
    }

    func test_VerticalSavedPaymentOptionsViewControllerSnapshotTestsAppearance() {
        _test_VerticalSavedPaymentOptionsViewControllerSnapshotTests(darkMode: false, appearance: ._testMSPaintTheme)
    }

    func _test_VerticalSavedPaymentOptionsViewControllerSnapshotTests(darkMode: Bool, appearance: PaymentSheet.Appearance = .default) {
        var configuration = PaymentSheet.Configuration()
        configuration.appearance = appearance
        let sut = VerticalSavedPaymentOptionsViewController(configuration: configuration)
        let testWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 500))
        testWindow.isHidden = false
        if darkMode {
            testWindow.overrideUserInterfaceStyle = .dark
        }
        testWindow.rootViewController = sut
        sut.view.autosizeHeight(width: 375, height: 280)
        STPSnapshotVerifyView(sut.view)
    }
}
