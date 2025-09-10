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

// ☠️ WARNING: These snapshots are missing selected borders at the corners on iOS 26 - this is a snapshot-test-only-bug and does not repro on simulator/device.
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

    func _test_all_saved_pms_and_apple_pay_and_link(darkMode: Bool, appearance: PaymentSheet.Appearance = .default.liquidGlassIfPossible, showDefaultPMBadge: Bool = false) {
        let paymentMethods = [
            STPPaymentMethod._testCard(),
            STPPaymentMethod._testUSBankAccount(),
            STPPaymentMethod._testSEPA(),
        ]
        let config = SavedPaymentOptionsViewController.Configuration(customerID: "cus_123", showApplePay: true, showLink: true, removeSavedPaymentMethodMessage: nil, merchantDisplayName: "Test Merchant", isCVCRecollectionEnabled: false, isTestMode: false, allowsRemovalOfLastSavedPaymentMethod: false, allowsRemovalOfPaymentMethods: true, allowsSetAsDefaultPM: showDefaultPMBadge, allowsUpdatePaymentMethod: false)
        let intent = Intent.deferredIntent(intentConfig: .init(mode: .payment(amount: 0, currency: "USD", setupFutureUsage: nil, captureMethod: .automatic), confirmHandler: { _, _, _ in }))
        let sut = SavedPaymentOptionsViewController(savedPaymentMethods: paymentMethods,
                                                    configuration: config,
                                                    paymentSheetConfiguration: PaymentSheet.Configuration(),
                                                    intent: intent,
                                                    appearance: appearance,
                                                    elementsSession: showDefaultPMBadge ? ._testDefaultCardValue(defaultPaymentMethod: paymentMethods.first?.stripeId ?? STPPaymentMethod._testCard().stripeId, paymentMethods: [testCardJSON, testUSBankAccountJSON, testSEPAJSON]) : .emptyElementsSession,
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
        if showDefaultPMBadge {
            sut.isRemovingPaymentMethods = true
        }
        NSLayoutConstraint.activate([
            sut.view.topAnchor.constraint(equalTo: testWindow.topAnchor),
            sut.view.leftAnchor.constraint(equalTo: testWindow.leftAnchor),
        ])
        STPSnapshotVerifyView(sut.view)
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
            "exp_year": "2040",
        ],
    ] as [AnyHashable: Any]
    private let testUSBankAccountJSON = [
        "id": "pm_123bank",
        "type": "us_bank_account",
        "us_bank_account": [
            "account_holder_type": "individual",
            "account_type": "checking",
            "bank_name": "STRIPE TEST BANK",
            "fingerprint": "ickfX9sbxIyAlbuh",
            "last4": "6789",
            "networks": [
              "preferred": "ach",
              "supported": [
                "ach",
              ],
            ] as [String: Any],
            "routing_number": "110000000",
        ] as [String: Any],
        "billing_details": [
            "name": "Sam Stripe",
            "email": "sam@stripe.com",
        ] as [String: Any],
    ] as [AnyHashable: Any]
    private let testSEPAJSON = [
        "id": "pm_123sepa",
        "type": "sepa_debit",
        "sepa_debit": [
            "last4": "1234",
        ],
        "billing_details": [
            "name": "Sam Stripe",
            "email": "sam@stripe.com",
        ] as [String: Any],
    ] as [AnyHashable: Any]

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
            removeSavedPaymentMethodMessage: nil,
            merchantDisplayName: "Test Merchant",
            isCVCRecollectionEnabled: true,
            isTestMode: false,
            allowsRemovalOfLastSavedPaymentMethod: false,
            allowsRemovalOfPaymentMethods: true,
            allowsSetAsDefaultPM: false,
            allowsUpdatePaymentMethod: false
        )
        let intent = Intent.deferredIntent(intentConfig: .init(mode: .payment(amount: 0, currency: "USD", setupFutureUsage: nil, captureMethod: .automatic), confirmHandler: { _, _, _ in }))
        let sut = SavedPaymentOptionsViewController(
            savedPaymentMethods: paymentMethods,
            configuration: config,
            paymentSheetConfiguration: PaymentSheet.Configuration(),
            intent: intent,
            appearance: .default.liquidGlassIfPossible,
            elementsSession: .emptyElementsSession,
            analyticsHelper: ._testValue()
        )
        sut.view.backgroundColor = PaymentSheet.Configuration().appearance.liquidGlassIfPossible.colors.background
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
