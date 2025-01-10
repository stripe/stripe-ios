//
//  UpdatePaymentMethodViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 11/27/23.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
import XCTest

final class UpdatePaymentMethodViewControllerSnapshotTests: STPSnapshotTestCase {

    func test_UpdatePaymentMethodViewControllerDarkMode() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: true, canUpdateCardBrand: true)
    }

    func test_UpdatePaymentMethodViewControllerLightMode() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, canUpdateCardBrand: true)
    }

    func test_UpdatePaymentMethodViewControllerAppearance() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, appearance: ._testMSPaintTheme, canUpdateCardBrand: true)
    }

    func test_EmbeddedSingleCard_UpdatePaymentMethodViewControllerDarkMode() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: true, isEmbeddedSingle: true, canUpdateCardBrand: true)
    }

    func test_EmbeddedSingleCard_UpdatePaymentMethodViewControllerLightMode() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, isEmbeddedSingle: true, canUpdateCardBrand: true)
    }

    func test_EmbeddedSingleCard_UpdatePaymentMethodViewControllerAppearance() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, isEmbeddedSingle: true, appearance: ._testMSPaintTheme, canUpdateCardBrand: true)
    }

    func test_UpdatePaymentMethodViewControllerExpiredCard() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, canUpdateCardBrand: true, expired: true)
    }

    func test_UpdatePaymentMethodViewControllerSetAsDefaultCard() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, canUpdateCardBrand: true, allowsSetAsDefaultPM: true)
    }

    func test_UpdatePaymentMethodViewControllerDefaultCard() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, canUpdateCardBrand: true, allowsSetAsDefaultPM: true, isDefault: true)
    }

    func test_UpdatePaymentMethodViewControllerRemoveOnlyCard() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false)
    }

    func test_UpdatePaymentMethodViewControllerUSBankAccountDarkMode() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .USBankAccount, darkMode: true)
    }

    func test_UpdatePaymentMethodViewControllerUSBankAccountLightMode() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .USBankAccount, darkMode: false)
    }

    func test_UpdatePaymentMethodViewControllerUSBankAccountAppearance() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .USBankAccount, darkMode: false, appearance: ._testMSPaintTheme)
    }

    func test_UpdatePaymentMethodViewControllerSetAsDefaultUSBankAccount() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .USBankAccount, darkMode: false, allowsSetAsDefaultPM: true)
    }

    func test_UpdatePaymentMethodViewControllerDefaultUSBankAccount() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .USBankAccount, darkMode: false, allowsSetAsDefaultPM: true, isDefault: true)
    }

    func test_EmbeddedSingleUSBankAccount_UpdatePaymentMethodViewControllerDarkMode() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .USBankAccount, darkMode: true, isEmbeddedSingle: true)
    }

    func test_EmbeddedSingleUSBankAccount_UpdatePaymentMethodViewControllerLightMode() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .USBankAccount, darkMode: false, isEmbeddedSingle: true)
    }

    func test_EmbeddedSingleUSBankAccount_UpdatePaymentMethodViewControllerAppearance() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .USBankAccount, darkMode: false, isEmbeddedSingle: true, appearance: ._testMSPaintTheme)
    }

    func test_UpdatePaymentMethodViewControllerSEPADebitDarkMode() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .SEPADebit, darkMode: true)
    }

    func test_UpdatePaymentMethodViewControllerSEPADebitLightMode() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .SEPADebit, darkMode: false)
    }

    func test_UpdatePaymentMethodViewControllerSEPADebitAppearance() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .SEPADebit, darkMode: false, appearance: ._testMSPaintTheme)
    }

    func test_UpdatePaymentMethodViewControllerSetAsDefaultSEPADebit() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .SEPADebit, darkMode: false, allowsSetAsDefaultPM: true)
    }

    func test_EmbeddedSingleSEPADebit_UpdatePaymentMethodViewControllerDarkMode() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .SEPADebit, darkMode: true, isEmbeddedSingle: true)
    }

    func test_EmbeddedSingleSEPADebit_UpdatePaymentMethodViewControllerLightMode() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .SEPADebit, darkMode: false, isEmbeddedSingle: true)
    }

    func test_EmbeddedSingleSEPADebit_UpdatePaymentMethodViewControllerAppearance() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .SEPADebit, darkMode: false, isEmbeddedSingle: true, appearance: ._testMSPaintTheme)
    }

    func _test_UpdatePaymentMethodViewController(paymentMethodType: STPPaymentMethodType, darkMode: Bool, isEmbeddedSingle: Bool = false, appearance: PaymentSheet.Appearance = .default, canRemove: Bool = true, canUpdateCardBrand: Bool = false, expired: Bool = false, allowsSetAsDefaultPM: Bool = false, isDefault: Bool = false) {
        let paymentMethod: STPPaymentMethod = {
            switch paymentMethodType {
            case .card:
                if expired {
                    return STPFixtures.paymentMethod()
                }
                else {
                    if canUpdateCardBrand {
                        return STPPaymentMethod._testCardCoBranded()
                    }
                    else {
                        return STPPaymentMethod._testCard()
                    }
                }
            case .USBankAccount:
                return STPPaymentMethod._testUSBankAccount()
            case .SEPADebit:
                return STPPaymentMethod._testSEPA()
            default:
                fatalError("Updating payment method has not been implemented for type \(paymentMethodType)")
            }
        }()
        let updateViewModel = UpdatePaymentMethodViewModel(paymentMethod: paymentMethod,
                                                           appearance: appearance,
                                                           hostedSurface: .paymentSheet,
                                                           canRemove: canRemove,
                                                           canUpdateCardBrand: canUpdateCardBrand,
                                                           allowsSetAsDefaultPM: allowsSetAsDefaultPM,
                                                           isDefault: isDefault
        )
        let sut = UpdatePaymentMethodViewController(
                                           removeSavedPaymentMethodMessage: "Test removal string",
                                           isTestMode: false,
                                           viewModel: updateViewModel)
        let bottomSheet: BottomSheetViewController
        if isEmbeddedSingle {
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

extension UIView {
    /// Constrains the view to the given width and autosizes its height.
    /// - Parameter width: Resizes the view to this width
    /// - Parameter height: Resizes the view to this height
    func autosizeHeight(width: CGFloat, height: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: width).isActive = true
        heightAnchor.constraint(equalToConstant: height).isActive = true
        setNeedsLayout()
        layoutIfNeeded()
        frame = .init(
            origin: .zero,
            size: systemLayoutSizeFitting(CGSize(width: width, height: height))
        )
    }
}
