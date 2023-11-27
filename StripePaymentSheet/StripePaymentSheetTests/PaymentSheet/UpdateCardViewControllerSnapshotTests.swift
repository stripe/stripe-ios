//
//  UpdateCardViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 11/27/23.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
import XCTest

final class UpdateCardViewControllerSnapshotTests: STPSnapshotTestCase {

    func test_UpdateCardViewControllerDarkMode() {
        _test_UpdateCardViewController(darkMode: true)
    }

    func test_UpdateCardViewControllerLightMode() {
        _test_UpdateCardViewController(darkMode: false)
    }

    func test_UpdateCardViewControllerAppearance() {
        _test_UpdateCardViewController(darkMode: false, appearance: ._testMSPaintTheme)
    }

    func _test_UpdateCardViewController(darkMode: Bool, appearance: PaymentSheet.Appearance = .default) {
        let sut = UpdateCardViewController(paymentOptionCell: .init(frame: .zero),
                                           paymentMethod: STPFixtures.paymentMethod(),
                                           removeSavedPaymentMethodMessage: "Test removal string",
                                           appearance: appearance)
        let testWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 500))
        testWindow.isHidden = false
        if darkMode {
            testWindow.overrideUserInterfaceStyle = .dark
        }
        testWindow.rootViewController = sut
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }
}
