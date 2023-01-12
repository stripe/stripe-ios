//
//  STPInputTextFieldValidatorTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/28/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPInputTextFieldValidatorTests: XCTestCase {

    class ObserverWithExpectation: NSObject, STPFormInputValidationObserver {

        let expectation: XCTestExpectation
        init(
            _ expectation: XCTestExpectation
        ) {
            self.expectation = expectation
            super.init()
        }

        func validationDidUpdate(
            to state: STPValidatedInputState,
            from previousState: STPValidatedInputState,
            for unformattedInput: String?,
            in input: STPFormInput
        ) {
            expectation.fulfill()
        }

    }

    func testUpdatingObservers() {
        let textField = STPInputTextField(
            formatter: STPInputTextFieldFormatter(),
            validator: STPInputTextFieldValidator()
        )
        let expectationForNewValue = expectation(description: "Receives expectation with new value")
        let observerForNewValue = ObserverWithExpectation(expectationForNewValue)
        let validator = textField.validator

        validator.addObserver(observerForNewValue)
        validator.validationState = STPValidatedInputState.valid(message: nil)
        wait(for: [expectationForNewValue], timeout: 1)
        validator.removeObserver(observerForNewValue)

        let expectationForSameValue = expectation(
            description: "Receives expectation with same value"
        )
        let observerForSameValue = ObserverWithExpectation(expectationForSameValue)
        validator.validationState = .incomplete(description: nil)
        validator.addObserver(observerForSameValue)
        validator.validationState = .incomplete(description: nil)
        wait(for: [expectationForSameValue], timeout: 1)
    }

}
