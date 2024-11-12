//
//  UpdatePaymentMethodViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Joyce Qin on 11/11/24.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
import XCTest

final class UpdatePaymentMethodViewControllerSnapshotTests: STPSnapshotTestCase {

    func test_UpdatePaymentMethodViewControllerDarkMode() {
        _test_UpdatePaymentMethodViewController(darkMode: true)
    }

    func test_UpdatePaymentMethodViewControllerLightMode() {
        _test_UpdatePaymentMethodViewController(darkMode: false)
    }

    func test_UpdatePaymentMethodViewControllerAppearance() {
        _test_UpdatePaymentMethodViewController(darkMode: false, appearance: ._testMSPaintTheme)
    }

    func test_EmbeddedSingleCard_UpdatePaymentMethodViewControllerDarkMode() {
        _test_UpdatePaymentMethodViewController(darkMode: true, isEmbeddedSingleCard: true)
    }

    func test_EmbeddedSingleCard_UpdatePaymentMethodViewControllerLightMode() {
        _test_UpdatePaymentMethodViewController(darkMode: false, isEmbeddedSingleCard: true)
    }

    func test_EmbeddedSingleCard_UpdatePaymentMethodViewControllerAppearance() {
        _test_UpdatePaymentMethodViewController(darkMode: false, isEmbeddedSingleCard: true, appearance: ._testMSPaintTheme)
    }

    func _test_UpdatePaymentMethodViewController(darkMode: Bool, isRemoveOnly: Bool = true, isEmbeddedSingleCard: Bool = false, appearance: PaymentSheet.Appearance = .default) {
        let sut = UpdatePaymentMethodViewController(paymentMethod: STPFixtures.paymentMethod(),
                                           removeSavedPaymentMethodMessage: "Test removal string",
                                           appearance: appearance,
                                           hostedSurface: .paymentSheet,
                                           canEditCard: isRemoveOnly ? false : true,
                                           canRemoveCard: true,
                                           isTestMode: false)
        let bottomSheet: BottomSheetViewController
        if isEmbeddedSingleCard {
            bottomSheet = BottomSheetViewController(contentViewController: sut, appearance: appearance, isTestMode: true, didCancelNative3DS2: {})
        } else {
            let stubViewController = StubBottomSheetContentViewController()
            bottomSheet = BottomSheetViewController(contentViewController: stubViewController, appearance: appearance, isTestMode: true, didCancelNative3DS2: {})
            bottomSheet.pushContentViewController(sut)
        }
        bottomSheet.view.autosizeHeight(width: 375)

        let testWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: bottomSheet.view.frame.size.height + sut.view.frame.size.height))
        testWindow.isHidden = false
        if darkMode {
            testWindow.overrideUserInterfaceStyle = .dark
        }
        testWindow.rootViewController = bottomSheet
        STPSnapshotVerifyView(bottomSheet.view)
    }
}
