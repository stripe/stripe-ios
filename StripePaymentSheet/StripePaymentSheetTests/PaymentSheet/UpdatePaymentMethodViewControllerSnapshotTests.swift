//
//  UpdatePaymentMethodViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 11/27/23.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
@testable@_spi(STP) import StripeUICore
import XCTest

// ☠️ WARNING: These snapshots are missing selected borders at the corners on iOS 26 - this is a snapshot-test-only-bug and does not repro on simulator/device.
// @iOS26
final class UpdatePaymentMethodViewControllerSnapshotTests: STPSnapshotTestCase {
    override func setUp() {
        super.setUp()
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func test_UpdatePaymentMethodViewControllerDarkMode() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: true, isCBCEligible: true)
    }

    // Due to limitations of snapshot tests, the snapshot recorded applies a border radius to all corners in SectionContainerView
    // More info: https://github.com/pointfreeco/swift-snapshot-testing/issues/358
    func test_UpdatePaymentMethodViewControllerLightMode() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, isCBCEligible: true)
    }

    // Due to limitations of snapshot tests, the snapshot recorded applies a border radius to all corners in SectionContainerView
    // More info: https://github.com/pointfreeco/swift-snapshot-testing/issues/358
    func test_UpdatePaymentMethodViewControllerLightMode_supressAddress_wCBC() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, addressCollectionMode: .automatic, canUpdate: false, isCBCEligible: true)
    }

    // Due to limitations of snapshot tests, the snapshot recorded applies a border radius to all corners in SectionContainerView
    // More info: https://github.com/pointfreeco/swift-snapshot-testing/issues/358
    func test_UpdatePaymentMethodViewControllerLightMode_BillingAuto_wCBC() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, addressCollectionMode: .automatic, canUpdate: true, isCBCEligible: true)
    }

    // Due to limitations of snapshot tests, the snapshot recorded applies a border radius to all corners in SectionContainerView
    // More info: https://github.com/pointfreeco/swift-snapshot-testing/issues/358
    func test_UpdatePaymentMethodViewControllerLightMode_BillingFull_wCBC() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, addressCollectionMode: .full, canUpdate: true, isCBCEligible: true)
    }

    // Due to limitations of snapshot tests, the snapshot recorded applies a border radius to all corners in SectionContainerView
    // More info: https://github.com/pointfreeco/swift-snapshot-testing/issues/358
    func test_UpdatePaymentMethodViewControllerLightMode_BillingAuto_woCBC() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, addressCollectionMode: .automatic, canUpdate: true, isCBCEligible: false)
    }

    // Due to limitations of snapshot tests, the snapshot recorded applies a border radius to all corners in SectionContainerView
    // More info: https://github.com/pointfreeco/swift-snapshot-testing/issues/358
    func test_UpdatePaymentMethodViewControllerLightMode_BillingFull_woCBC() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, addressCollectionMode: .full, canUpdate: true, isCBCEligible: false)
    }

    // Due to limitations of snapshot tests, the snapshot recorded applies a border radius to all corners in SectionContainerView
    // More info: https://github.com/pointfreeco/swift-snapshot-testing/issues/358
    func test_UpdatePaymentMethodViewControllerCanUpdateLightMode() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, canUpdate: true, isCBCEligible: true)
    }

    func test_UpdatePaymentMethodViewControllerAppearance() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, appearance: ._testMSPaintTheme, isCBCEligible: true)
    }

    // Due to limitations of snapshot tests, the snapshot recorded applies a border radius to all corners in SectionContainerView
    // More info: https://github.com/pointfreeco/swift-snapshot-testing/issues/358
    func test_UpdatePaymentMethodViewControllerCanUpdateAppearance() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, appearance: ._testMSPaintTheme, canUpdate: true, isCBCEligible: true)
    }

    // Due to limitations of snapshot tests, the snapshot recorded applies a border radius to all corners in SectionContainerView
    // More info: https://github.com/pointfreeco/swift-snapshot-testing/issues/358
    func test_UpdatePaymentMethodViewControllerExpiredCard() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, isCBCEligible: true, expired: true)
    }

    // Due to limitations of snapshot tests, the snapshot recorded applies a border radius to all corners in SectionContainerView
    // More info: https://github.com/pointfreeco/swift-snapshot-testing/issues/358
    func test_UpdatePaymentMethodViewControllerCanUpdateExpiredCard() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, canUpdate: true, isCBCEligible: true, expired: true)
    }

    // Due to limitations of snapshot tests, the snapshot recorded applies a border radius to all corners in SectionContainerView
    // More info: https://github.com/pointfreeco/swift-snapshot-testing/issues/358
    func test_UpdatePaymentMethodViewControllerSetAsDefaultCard() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, isCBCEligible: true, canSetAsDefaultPM: true)
    }

    // Due to limitations of snapshot tests, the snapshot recorded applies a border radius to all corners in SectionContainerView
    // More info: https://github.com/pointfreeco/swift-snapshot-testing/issues/358
    func test_UpdatePaymentMethodViewControllerCanUpdateSetAsDefaultCard() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, canUpdate: true, isCBCEligible: true, canSetAsDefaultPM: true)
    }

    // Due to limitations of snapshot tests, the snapshot recorded applies a border radius to all corners in SectionContainerView
    // More info: https://github.com/pointfreeco/swift-snapshot-testing/issues/358
    func test_UpdatePaymentMethodViewControllerDefaultCard() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, isCBCEligible: true, canSetAsDefaultPM: true, isDefault: true)
    }

    // Due to limitations of snapshot tests, the snapshot recorded applies a border radius to all corners in SectionContainerView
    // More info: https://github.com/pointfreeco/swift-snapshot-testing/issues/358
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
        _test_UpdatePaymentMethodViewController(paymentMethodType: .USBankAccount, darkMode: false, canSetAsDefaultPM: true)
    }

    func test_UpdatePaymentMethodViewControllerDefaultUSBankAccount() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .USBankAccount, darkMode: false, canSetAsDefaultPM: true, isDefault: true)
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
        _test_UpdatePaymentMethodViewController(paymentMethodType: .SEPADebit, darkMode: false, canSetAsDefaultPM: true)
    }

    // Due to limitations of snapshot tests, the snapshot recorded applies a border radius to all corners in SectionContainerView
    // More info: https://github.com/pointfreeco/swift-snapshot-testing/issues/358
    func test_UpdatePaymentMethodViewControllerLightMode_blockedBrands() {
        let cardBrandFilter = CardBrandFilter(cardBrandAcceptance: .disallowed(brands: [.amex]))
        _test_UpdatePaymentMethodViewController(paymentMethodType: .card, darkMode: false, isCBCEligible: true, cardBrandFilter: cardBrandFilter)
    }

    func test_UpdatePaymentMethodViewControllerLink_lightMode() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .link, darkMode: false)
    }

    func test_UpdatePaymentMethodViewControllerLink_darkMode() {
        _test_UpdatePaymentMethodViewController(paymentMethodType: .link, darkMode: true)
    }

    func _test_UpdatePaymentMethodViewController(paymentMethodType: STPPaymentMethodType,
                                                 darkMode: Bool,
                                                 appearance: PaymentSheet.Appearance = .default.applyingLiquidGlassIfPossible(),
                                                 addressCollectionMode: PaymentSheet.BillingDetailsCollectionConfiguration.AddressCollectionMode = .never,
                                                 canRemove: Bool = true,
                                                 canUpdate: Bool = false,
                                                 isCBCEligible: Bool = false,
                                                 expired: Bool = false,
                                                 canSetAsDefaultPM: Bool = false,
                                                 isDefault: Bool = false,
                                                 cardBrandFilter: CardBrandFilter = .default) {
        let paymentMethod: STPPaymentMethod = {
            switch paymentMethodType {
            case .card:
                if expired {
                    return STPFixtures.paymentMethod()
                } else {
                    if isCBCEligible {
                        return STPPaymentMethod._testCardCoBranded()
                    } else {
                        return STPPaymentMethod._testCard()
                    }
                }
            case .USBankAccount:
                return STPPaymentMethod._testUSBankAccount()
            case .SEPADebit:
                return STPPaymentMethod._testSEPA()
            case .link:
                return STPPaymentMethod._testLink()
            default:
                fatalError("Updating payment method has not been implemented for type \(paymentMethodType)")
            }
        }()
        let billingDetailsCollectionConfiguration = PaymentSheet.BillingDetailsCollectionConfiguration(name: .never,
                                                                                                       phone: .never,
                                                                                                       email: .never,
                                                                                                       address: addressCollectionMode)
        let updateConfig = UpdatePaymentMethodViewController.Configuration(paymentMethod: paymentMethod,
                                                                           appearance: appearance,
                                                                           billingDetailsCollectionConfiguration: billingDetailsCollectionConfiguration,
                                                                           hostedSurface: .paymentSheet,
                                                                           cardBrandFilter: cardBrandFilter,
                                                                           canRemove: canRemove,
                                                                           canUpdate: canUpdate,
                                                                           isCBCEligible: isCBCEligible,
                                                                           allowsSetAsDefaultPM: canSetAsDefaultPM,
                                                                           isDefault: isDefault
        )
        let sut = UpdatePaymentMethodViewController(
            removeSavedPaymentMethodMessage: "Test removal string",
            isTestMode: false,
            configuration: updateConfig
        )
        let stubViewController = StubBottomSheetContentViewController()
        let bottomSheet = BottomSheetViewController(contentViewController: stubViewController, appearance: appearance, isTestMode: true, didCancelNative3DS2: {})
        bottomSheet.pushContentViewController(sut)
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
