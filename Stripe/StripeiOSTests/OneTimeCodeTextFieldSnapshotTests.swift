//
//  OneTimeCodeTextFieldSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 11/10/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCase
import StripeCoreTestUtils
import UIKit

@testable@_spi(InternalOnlyAPI) import Stripe
@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripePaymentsUI
@testable@_spi(InternalOnlyAPI) import StripeUICore

class OneTimeCodeTextFieldSnapshotTests: STPSnapshotTestCase {

    func testEmpty() {
        let field = OneTimeCodeTextField(
            configuration: OneTimeCodeTextField.Configuration(
                numberOfDigits: 6
            ),
            theme: .default
        )
        verify(field)
    }

    func testFilled() {
        let field = OneTimeCodeTextField(
            configuration: OneTimeCodeTextField.Configuration(
                numberOfDigits: 6
            ),
            theme: .default
        )
        field.value = "123456"
        verify(field)
    }

    func testDisabled() {
        let field = OneTimeCodeTextField(
            configuration: OneTimeCodeTextField.Configuration(
                numberOfDigits: 6
            ),
            theme: .default
        )
        field.value = "123456"
        field.isEnabled = false
        verify(field)
    }

    func verify(
        _ view: UIView,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 300)
        STPSnapshotVerifyView(view, file: file, line: line)
    }
}
