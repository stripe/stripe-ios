//
//  STPPaymentCardTextFieldValueChangedTest.swift
//  StripeiOSTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import StripeCore
import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentsTestUtils
@testable @_spi(InternalOnlyAPI) import StripePaymentsUI
import UIKit
import XCTest

/// `STPPaymentCardTextField.isValid` isn't key-value observable, so merchants observe it through
/// the `.valueChanged` control event (or the delegate). These tests cover that replacement.
class STPPaymentCardTextFieldValueChangedTest: XCTestCase {
    /// Records `.valueChanged` events, since control events can't be dispatched to targets without a host app.
    private class ValueChangedRecordingTextField: STPPaymentCardTextField {
        var valueChangedEventCount = 0

        override func sendActions(for controlEvents: UIControl.Event) {
            if controlEvents.contains(.valueChanged) {
                valueChangedEventCount += 1
            }
            super.sendActions(for: controlEvents)
        }
    }

    private var window: UIWindow!
    private var sut: ValueChangedRecordingTextField!

    override class func setUp() {
        super.setUp()
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey // swiftlint:disable:this no_shared_api_client_mutation_in_tests
    }

    override class func tearDown() {
        STPAPIClient.shared.publishableKey = nil // swiftlint:disable:this no_shared_api_client_mutation_in_tests
        super.tearDown()
    }

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: UIScreen.main.bounds)
        sut = ValueChangedRecordingTextField(frame: window.bounds)
        window.addSubview(sut)
        XCTAssertTrue(sut.numberField.canBecomeFirstResponder, "text field cannot become first responder")
    }

    func testValueChangedIsSentWhenCardBecomesValid() {
        // Given a card that is missing only its CVC
        sut.numberField.text = "4242424242424242"
        sut.expirationField.text = "10/50"
        sut.postalCodeField.text = "90210"
        XCTAssertFalse(sut.isValid)
        let eventCountBeforeCVC = sut.valueChangedEventCount

        // When the CVC is entered
        sut.cvcField.text = "123"

        // Then the field is valid and sent a `.valueChanged` event
        XCTAssertTrue(sut.isValid)
        XCTAssertGreaterThan(sut.valueChangedEventCount, eventCountBeforeCVC)
    }

    func testPaymentCardTextFieldCanSetPreferredNetworks() {
        // When preferred networks are set
        sut.preferredNetworks = [.visa]

        // Then they can be read back
        XCTAssertEqual(sut.preferredNetworks, [.visa])
    }
}
