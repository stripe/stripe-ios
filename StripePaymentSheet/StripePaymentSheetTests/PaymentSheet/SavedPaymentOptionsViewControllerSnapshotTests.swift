//
//  SavedPaymentOptionsViewControllerSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 10/13/23.
//

@_spi(STP) @testable import StripeCore
import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
@_spi(STP) @testable import StripeUICore
import XCTest

// ☠️ WARNING: These snapshots have selected borders that don't follow the correct curvature on iOS 26 - this is a snapshot-test-only-bug and does not repro on simulator/device.
// @iOS26
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

    func test_all_saved_pms_and_apple_pay_and_link_default_badge() {
        _test_all_saved_pms_and_apple_pay_and_link(darkMode: false, showDefaultPMBadge: true)
    }

    func test_all_saved_pms_editing_right_to_left() {
        _test_all_saved_pms_and_apple_pay_and_link(
            darkMode: false,
            showDefaultPMBadge: true,
            rightToLeft: true
        )
    }

    func _test_all_saved_pms_and_apple_pay_and_link(
        darkMode: Bool,
        appearance: PaymentSheet.Appearance = .default.applyingLiquidGlassIfPossible(),
        showDefaultPMBadge: Bool = false,
        rightToLeft: Bool = false
    ) {
        let paymentMethods = [
            STPPaymentMethod._testCard(),
            STPPaymentMethod._testUSBankAccount(),
            STPPaymentMethod._testSEPA(),
        ]
        let config = SavedPaymentOptionsViewController.Configuration(customerID: "cus_123", showApplePay: true, showLink: true, linkBrand: .link, removeSavedPaymentMethodMessage: nil, merchantDisplayName: "Test Merchant", isCVCRecollectionEnabled: false, isTestMode: false, allowsRemovalOfLastSavedPaymentMethod: false, allowsRemovalOfPaymentMethods: true, allowsSetAsDefaultPM: showDefaultPMBadge, allowsUpdatePaymentMethod: false)
        let intent = Intent.deferredIntent(intentConfig: .init(mode: .payment(amount: 0, currency: "USD", setupFutureUsage: nil, captureMethod: .automatic), confirmHandler: { _, _ in return "" }))
        let sut = SavedPaymentOptionsViewController(
            savedPaymentMethods: paymentMethods,
            configuration: config,
            paymentSheetConfiguration: PaymentSheet.Configuration(),
            intent: intent,
            appearance: appearance,
            elementsSession: showDefaultPMBadge ? ._testDefaultCardValue(
                defaultPaymentMethod: paymentMethods.first?.stripeId ?? STPPaymentMethod._testCard().stripeId,
                paymentMethods: [
                    STPPaymentMethod._testCardJSON,
                    STPPaymentMethod._testUSBankAccount().allResponseFields,
                    STPPaymentMethod._testSEPA().allResponseFields,
                ]
            ) : .emptyElementsSession,
            analyticsHelper: ._testValue()
        )
        let testWindow = UIWindow()
        testWindow.isHidden = false
        if darkMode {
            testWindow.overrideUserInterfaceStyle = .dark
        }
        let rootViewController: UIViewController
        if rightToLeft {
            let hostViewController = UIViewController()
            hostViewController.addChild(sut)
            hostViewController.setOverrideTraitCollection(
                UITraitCollection(layoutDirection: .rightToLeft),
                forChild: sut
            )
            rootViewController = hostViewController
        } else {
            rootViewController = sut
        }
        testWindow.rootViewController = rootViewController
        // Adding sut.view as the subview should be implied by the above line, but Autolayout can't lay out the view correctly on this pass of the runloop unless we explicitly addSubview. Maybe there are side effects that happen one turn of the runloop after setting the rootViewController.
        rootViewController.view.addSubview(sut.view)
        if rightToLeft {
            sut.didMove(toParent: rootViewController)
        }
        sut.view.autosizeHeight(width: 1000)
        if showDefaultPMBadge {
            sut.isRemovingPaymentMethods = true
        }
        NSLayoutConstraint.activate([
            sut.view.topAnchor.constraint(equalTo: rootViewController.view.topAnchor),
            sut.view.leftAnchor.constraint(equalTo: rootViewController.view.leftAnchor),
        ])
        XCTAssertEqual(
            sut.view.effectiveUserInterfaceLayoutDirection,
            rightToLeft ? .rightToLeft : .leftToRight
        )
        STPSnapshotVerifyView(sut.view)
    }

    func test_cvc_recollection() {
        _test_cvc_recollection(darkMode: false)
    }

    func test_cvc_recollection_dark() {
        _test_cvc_recollection(darkMode: true)
    }

    func _test_cvc_recollection(darkMode: Bool) {
        let paymentMethods = [
            STPPaymentMethod._testCard(),
            STPPaymentMethod._testUSBankAccount(),
        ]
        let config = SavedPaymentOptionsViewController.Configuration(
            customerID: "cus_123",
            showApplePay: false,
            showLink: false,
            linkBrand: .link,
            removeSavedPaymentMethodMessage: nil,
            merchantDisplayName: "Test Merchant",
            isCVCRecollectionEnabled: true,
            isTestMode: false,
            allowsRemovalOfLastSavedPaymentMethod: false,
            allowsRemovalOfPaymentMethods: true,
            allowsSetAsDefaultPM: false,
            allowsUpdatePaymentMethod: false
        )
        let intent = Intent.deferredIntent(intentConfig: .init(mode: .payment(amount: 0, currency: "USD", setupFutureUsage: nil, captureMethod: .automatic), confirmHandler: { _, _ in return "" }))
        let sut = SavedPaymentOptionsViewController(
            savedPaymentMethods: paymentMethods,
            configuration: config,
            paymentSheetConfiguration: PaymentSheet.Configuration(),
            intent: intent,
            appearance: .default.applyingLiquidGlassIfPossible(),
            elementsSession: .emptyElementsSession,
            analyticsHelper: ._testValue()
        )
        sut.view.backgroundColor = PaymentSheet.Configuration().appearance.applyingLiquidGlassIfPossible().colors.background
        let testWindow = UIWindow()
        testWindow.isHidden = false
        if darkMode {
            testWindow.overrideUserInterfaceStyle = .dark
        }
        testWindow.rootViewController = sut
        testWindow.addSubview(sut.view)

        sut.viewDidLoad()
        sut.viewWillAppear(false)
        sut.viewDidAppear(false)

        sut.view.autosizeHeight(width: 1000)
        NSLayoutConstraint.activate([
            sut.view.topAnchor.constraint(equalTo: testWindow.topAnchor),
            sut.view.leftAnchor.constraint(equalTo: testWindow.leftAnchor),
        ])

        let expectation = XCTestExpectation(description: "Wait for CVC recollection display")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        STPSnapshotVerifyView(sut.view)
    }
}
