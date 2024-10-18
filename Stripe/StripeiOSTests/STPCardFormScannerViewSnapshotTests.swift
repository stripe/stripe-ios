//
//  STPCardFormScannerViewSnapshotTests.swift
//  StripeiOS Tests
//
//  Copyright © 2024 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCase
import StripeCoreTestUtils

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPCardFormScannerViewSnapshotTests: STPSnapshotTestCase {
    class MockCardScanner: StripePaymentsUI.STPCardScanner {
        override func start() {}
        override func stop() {}
    }

    func testWithFullBillingDetailsWithScanner() {
        let formScannerView = STPCardFormScannerView(MockCardScanner(), style: .standard, handleError: nil)
        formScannerView.countryCode = "US"
        formScannerView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 400))
        formScannerView.startScanCard()

        let exp = expectation(description: "Waiting for layout")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.STPSnapshotVerifyView(formScannerView)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testEmpty() {
        let formScannerView = STPCardFormScannerView(billingAddressCollection: .automatic)
        formScannerView.countryCode = "US"
        formScannerView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 225))

        STPSnapshotVerifyView(formScannerView)
    }

    func testIncomplete() {
        let formScannerView = STPCardFormScannerView(billingAddressCollection: .automatic)
        formScannerView.countryCode = "US"
        formScannerView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 265))

        formScannerView.numberField.text = "4242"
        formScannerView.numberField.textDidChange()
        formScannerView.cvcField.text = "123"
        formScannerView.cvcField.textDidChange()

        STPSnapshotVerifyView(formScannerView)
    }

    // valid expiration date will change over time so we just test without it
    func testCompleteWithoutExpiry() {
        let formScannerView = STPCardFormScannerView(billingAddressCollection: .automatic)
        formScannerView.countryCode = "US"
        formScannerView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 225))

        formScannerView.numberField.text = "4242424242424242"
        formScannerView.numberField.textDidChange()
        formScannerView.cvcField.text = "123"
        formScannerView.cvcField.textDidChange()
        formScannerView.postalCodeField.text = "12345"

        STPSnapshotVerifyView(formScannerView)
    }

    func testEmptyHiddenPostalCode() {
        let formScannerView = STPCardFormScannerView(billingAddressCollection: .automatic)
        formScannerView.countryCode = "AE"
        formScannerView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 225))

        STPSnapshotVerifyView(formScannerView)
    }

    func testWithFullBillingDetails() {
        let formScannerView = STPCardFormScannerView(billingAddressCollection: .required)
        formScannerView.countryCode = "US"
        formScannerView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 400))

        STPSnapshotVerifyView(formScannerView)
    }

    // MARK: - Standalone

    func testDefaultStandalone() {
        let formScannerView = STPCardFormScannerView()
        formScannerView.countryCode = "US"
        formScannerView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 225))

        STPSnapshotVerifyView(formScannerView)
    }

    func testBorderlessStandalone() {
        let formScannerView = STPCardFormScannerView(style: .borderless)
        formScannerView.countryCode = "US"
        formScannerView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 225))

        STPSnapshotVerifyView(formScannerView)
    }

    func testCustomBackgroundStandalone() {
        let formScannerView = STPCardFormScannerView()
        formScannerView.countryCode = "US"
        formScannerView.backgroundColor = .green
        formScannerView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 225))

        STPSnapshotVerifyView(formScannerView)
    }

    func testCustomBackgroundDisabledColorStandalone() {
        let formScannerView = STPCardFormScannerView()
        formScannerView.countryCode = "US"
        formScannerView.disabledBackgroundColor = .green
        formScannerView.isUserInteractionEnabled = false
        formScannerView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 225))

        STPSnapshotVerifyView(formScannerView)
    }

    func testBorderlessStandaloneIncomplete() {
        let formScannerView = STPCardFormScannerView(style: .borderless)
        formScannerView.countryCode = "US"
        formScannerView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 225))

        formScannerView.numberField.text = "4242"
        formScannerView.numberField.textDidChange()
        formScannerView.cvcField.text = "123"
        formScannerView.cvcField.textDidChange()

        STPSnapshotVerifyView(formScannerView)
    }

    func testCBC() {
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey
        let formScannerView = STPCardFormScannerView(billingAddressCollection: .automatic, cbcEnabledOverride: true)
        formScannerView.countryCode = "US"
        formScannerView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 225))
        formScannerView.numberField.text = "4973019750239993"
        formScannerView.numberField.textDidChange()
        formScannerView.cvcField.text = "123"
        formScannerView.cvcField.textDidChange()
        formScannerView.postalCodeField.text = "12345"
        let exp = expectation(description: "Wait for CBC load")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.STPSnapshotVerifyView(formScannerView)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3.0)
    }

    func testCBCPreselectVisa() {
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey
        let formScannerView = STPCardFormScannerView(billingAddressCollection: .automatic, cbcEnabledOverride: true)
        formScannerView.countryCode = "US"
        formScannerView.frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 225))

        formScannerView.numberField.text = "4973019750239993"
        formScannerView.numberField.textDidChange()
        formScannerView.cvcField.text = "123"
        formScannerView.cvcField.textDidChange()
        formScannerView.postalCodeField.text = "12345"
        formScannerView.preferredNetworks = [.visa]
        let exp = expectation(description: "Wait for CBC load")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.STPSnapshotVerifyView(formScannerView)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3.0)
    }
}
