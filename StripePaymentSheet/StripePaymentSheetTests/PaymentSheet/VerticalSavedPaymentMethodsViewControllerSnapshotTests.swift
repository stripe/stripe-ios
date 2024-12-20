//
//  VerticalSavedPaymentMethodsViewControllerSnapshotTests.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/7/24.
//

import StripeCoreTestUtils
@_spi(STP) @_spi(EmbeddedPaymentElementPrivateBeta) @testable import StripePaymentSheet
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

    func test_Embedded_VerticalSavedPaymentOptionsViewControllerSnapshotTestsDarkMode() {
        _test_VerticalSavedPaymentMethodsViewControllerSnapshotTests(darkMode: true, isEmbedded: true)
    }

    func test_Embedded_VerticalSavedPaymentMethodsViewControllerSnapshotTestsLightMode() {
        _test_VerticalSavedPaymentMethodsViewControllerSnapshotTests(darkMode: false, isEmbedded: true)
    }

    func test_Embedded_VerticalSavedPaymentMethodsViewControllerSnapshotTestsAppearance() {
        _test_VerticalSavedPaymentMethodsViewControllerSnapshotTests(darkMode: false, appearance: ._testMSPaintTheme, isEmbedded: true)
    }

    func test_VerticalSavedPaymentOptionsViewControllerSnapshotTestsDefaultBadge() {
        _test_VerticalSavedPaymentMethodsViewControllerSnapshotTests(darkMode: false, showDefaultPMBadge: true)
    }

    func _test_VerticalSavedPaymentMethodsViewControllerSnapshotTests(darkMode: Bool, appearance: PaymentSheet.Appearance = .default, isEmbedded: Bool = false, showDefaultPMBadge: Bool = false) {
        var configuration = PaymentSheet.Configuration()
        configuration.appearance = appearance
        var paymentMethods = generatePaymentMethods()
        if showDefaultPMBadge {
            configuration.allowsSetAsDefaultPM = true
            let card = STPPaymentMethod._testCard()
            paymentMethods.insert(card, at: 0)
        }

        let sut = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                            selectedPaymentMethod: paymentMethods.first,
                                                            paymentMethods: paymentMethods,
                                                            elementsSession: showDefaultPMBadge ? ._testDefaultCardValue(defaultPaymentMethod: paymentMethods.first?.stripeId ?? STPPaymentMethod._testCard().stripeId, paymentMethods: [testCardJSON]) : ._testCardValue(),
                                                            analyticsHelper: ._testValue()
        )
        let bottomSheet: BottomSheetViewController
        if isEmbedded {
            // In embedded, VerticalSavedPaymentMethodsViewController is the only contentViewController
            bottomSheet = BottomSheetViewController(contentViewController: sut, appearance: appearance, isTestMode: true, didCancelNative3DS2: {})
        } else {
            // In vertical mode, VerticalSavedPaymentMethodsViewController pushed onto the contentStack after PaymentSheetVerticalViewController
            // Use StubBottomSheetContentViewController as a convenience to rather than instantiating PaymentSheetVerticalViewController
            let stubViewController = StubBottomSheetContentViewController()
            bottomSheet = BottomSheetViewController(contentViewController: stubViewController, appearance: appearance, isTestMode: true, didCancelNative3DS2: {})
            bottomSheet.pushContentViewController(sut)
        }
        bottomSheet.view.autosizeHeight(width: 375)

        let testWindow = UIWindow(frame: CGRect(x: 0,
                                                y: 0,
                                                width: 375,
                                                height: bottomSheet.view.frame.size.height + sut.view.frame.size.height))
        testWindow.isHidden = false
        if darkMode {
            testWindow.overrideUserInterfaceStyle = .dark
        }
        testWindow.rootViewController = bottomSheet
        STPSnapshotVerifyView(bottomSheet.view)
    }

    private func generatePaymentMethods() -> [STPPaymentMethod] {
        return [
                STPFixtures.paymentMethod(),
                STPFixtures.usBankAccountPaymentMethod(),
                STPFixtures.usBankAccountPaymentMethod(bankName: "BANK OF AMERICA"),
                STPFixtures.usBankAccountPaymentMethod(bankName: "STRIPE"),
                STPFixtures.sepaDebitPaymentMethod(), ]
    }

    private let testCardJSON = [
        "id": "pm_123card",
        "type": "card",
        "card": [
            "last4": "4242",
            "brand": "visa",
            "fingerprint": "B8XXs2y2JsVBtB9f",
            "networks": ["available": ["visa"]],
            "exp_month": "01",
            "exp_year": Calendar.current.component(.year, from: Date()) + 1
        ]
    ] as [AnyHashable : Any]
}

final class StubBottomSheetContentViewController: UIViewController, BottomSheetContentViewController {
    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: false, appearance: .default)
        navBar.setStyle(.close(showAdditionalButton: false))
        return navBar
    }()

    var requiresFullScreen: Bool {
        return false
    }

    func didTapOrSwipeToDismiss() {
        // noop
    }
}
