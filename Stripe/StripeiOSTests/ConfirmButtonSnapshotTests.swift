//
//  ConfirmButtonSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Nick Porter on 3/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import iOSSnapshotTestCase
import StripeCoreTestUtils
import UIKit

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePaymentSheet

class ConfirmButtonSnapshotTests: STPSnapshotTestCase {

    func testConfirmButton() {
        let confirmButton = ConfirmButton(style: .stripe, callToAction: .setup, didTap: {})

        verify(confirmButton)
    }

    // Tests that `primaryButton` appearance is used over standard variables
    func testConfirmButtonBackgroundColor() {
        var appearance = PaymentSheet.Appearance.default
        var button = PaymentSheet.Appearance.PrimaryButton()
        button.backgroundColor = .red
        appearance.primaryButton = button

        let confirmButton = ConfirmButton(
            style: .stripe,
            callToAction: .setup,
            appearance: appearance,
            didTap: {}
        )

        verify(confirmButton)
    }

    func testConfirmButtonCustomFont() throws {
        var appearance = PaymentSheet.Appearance.default
        appearance.font.base = try XCTUnwrap(UIFont(name: "AmericanTypewriter", size: 12.0))

        let confirmButton = ConfirmButton(
            style: .stripe,
            callToAction: .custom(title: "Custom Title"),
            appearance: appearance,
            didTap: {}
        )

        verify(confirmButton)
    }

    func testConfirmButtonCustomFontScales() throws {
        var appearance = PaymentSheet.Appearance.default
        appearance.font.base = try XCTUnwrap(UIFont(name: "AmericanTypewriter", size: 12.0))
        appearance.font.sizeScaleFactor = 0.85

        let confirmButton = ConfirmButton(
            style: .stripe,
            callToAction: .custom(title: "Custom Title"),
            appearance: appearance,
            didTap: {}
        )

        verify(confirmButton)
    }
    
    // Tests that `primaryButton` disabled color is correct for the default theme
    func testConfirmButtonDefaultDisabledColor() {
        let confirmButton = ConfirmButton(
            state: .disabled,
            style: .stripe,
            callToAction: .setup,
            appearance: .default,
            didTap: {}
        )

        verify(confirmButton)
    }
    
    // Tests that `primaryButton` disabled color matches the primary color when no background color or diabled color set
    func testConfirmButtonDisabledColorWhenSetPrimaryColorAndNoSetBackgroundColorOrDisabledColor() {
        var appearance = PaymentSheet.Appearance.default
        var button = PaymentSheet.Appearance.PrimaryButton()
        button.disabledTextColor = .green.withAlphaComponent(0.6)
        appearance.primaryButton = button
        appearance.colors.primary = .yellow
        

        let confirmButton = ConfirmButton(
            state: .disabled,
            style: .stripe,
            callToAction: .setup,
            appearance: appearance,
            didTap: {}
        )

        verify(confirmButton)
    }
    
    // Tests that `primaryButton` disabled color matches the background color when background color is set but disabled color is not
    func testConfirmButtonDisabledColorWhenSetBackgroundColorAndNoSetDisabledColor() {
        var appearance = PaymentSheet.Appearance.default
        var button = PaymentSheet.Appearance.PrimaryButton()
        button.backgroundColor = .yellow
        button.disabledTextColor = .green.withAlphaComponent(0.6)
        appearance.primaryButton = button
        

        let confirmButton = ConfirmButton(
            state: .disabled,
            style: .stripe,
            callToAction: .setup,
            appearance: appearance,
            didTap: {}
        )

        verify(confirmButton)
    }
    
    // Tests that `primaryButton` disabled color matches the disabled color when disabled color, background color, and primary color are set
    func testConfirmButtonDisabledColorWhenSetDisabledBackgroundAndPrimaryColors() {
        var appearance = PaymentSheet.Appearance.default
        var button = PaymentSheet.Appearance.PrimaryButton()
        button.backgroundColor = .red
        button.disabledBackgroundColor = .black
        button.disabledTextColor = .green.withAlphaComponent(0.6)
        appearance.primaryButton = button
        appearance.colors.primary = .yellow
        

        let confirmButton = ConfirmButton(
            state: .disabled,
            style: .stripe,
            callToAction: .setup,
            appearance: appearance,
            didTap: {}
        )

        verify(confirmButton)
    }

    // Tests that `primaryButton` disabled color is updated properly
    func testConfirmButtonDisabledColor() {
        var appearance = PaymentSheet.Appearance.default
        var button = PaymentSheet.Appearance.PrimaryButton()
        button.disabledBackgroundColor = .red
        button.disabledTextColor = .green.withAlphaComponent(0.6)
        appearance.primaryButton = button

        let confirmButton = ConfirmButton(
            state: .disabled,
            style: .stripe,
            callToAction: .setup,
            appearance: appearance,
            didTap: {}
        )

        verify(confirmButton)
    }

    // Tests that `primaryButton` success color is correct for the default theme
    func testConfirmButtonDefaultSuccessColor() {
        let confirmButton = ConfirmButton(
            state: .succeeded,
            style: .stripe,
            callToAction: .setup,
            appearance: .default,
            didTap: {}
        )

        verify(confirmButton)
    }

    // Tests that `primaryButton` success color is updated properly
    func testConfirmButtonSuccessColor() {
        var appearance = PaymentSheet.Appearance.default
        var button = PaymentSheet.Appearance.PrimaryButton()
        button.successBackgroundColor = .red
        button.successTextColor = .green
        appearance.primaryButton = button

        let confirmButton = ConfirmButton(
            state: .succeeded,
            style: .stripe,
            callToAction: .setup,
            appearance: appearance,
            didTap: {}
        )

        verify(confirmButton)
    }

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 300)
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}
