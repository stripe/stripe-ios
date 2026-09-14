//
//  BiometricConsentViewControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 2/14/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit
import XCTest

// swift-format-ignore
@_spi(STP) @testable import StripeIdentity

final class BiometricConsentViewControllerTest: XCTestCase {

    static let mockVerificationPage = try! VerificationPageMock.response200.make()

    private var vc: BiometricConsentViewController!
    private var mockSheetController = VerificationSheetControllerMock()

    override func setUp() {
        super.setUp()

        vc = try! BiometricConsentViewController(
            brandLogo: UIImage(),
            showsStripeLogo: !BiometricConsentViewControllerTest.mockVerificationPage.isStripe,
            consentContent: BiometricConsentViewControllerTest.mockVerificationPage
                .biometricConsent,
            sheetController: mockSheetController
        )
    }

    func testAccept() {
        vc.scrolledToBottom = true
        // Tap accept button
        vc.flowViewModel.buttons.first?.didTap()

        // Verify biometricConsent is saved
        XCTAssertEqual(mockSheetController.savedData?.biometricConsent, true)
    }

    func testDeny() {
        // Tap accept button
        vc.flowViewModel.buttons.last?.didTap()

        // Verify biometricConsent is saved
        XCTAssertEqual(mockSheetController.savedData?.biometricConsent, false)
    }

    func testDefaultContinueButtonUsesTintColor() throws {
        for configuration: IdentityVerificationSheet.Configuration.BiometricConsentConfiguration? in [nil, .init(hideBrandingHeader: true)] {
            // Given the default style, including a header-only configuration
            let controller = try makeViewController(configuration: configuration)
            controller.view.tintColor = .magenta

            // When the user has read the consent
            controller.scrolledToBottom = true

            // Then the Continue button keeps the app's tint color
            let button = try XCTUnwrap(buttons(in: controller.view).first)
            XCTAssertEqual(button.backgroundColor, .magenta)
            let label = try XCTUnwrap(button.subviews.compactMap { $0 as? UILabel }.first)
            XCTAssertEqual(label.textColor, .white)
        }
    }

    func testCustomContinueButtonColors() throws {
        // Given caller-supplied button colors that differ from the app's tint
        let controller = try makeViewController(
            primaryButtonStyle: .custom(backgroundColor: .purple, textColor: .yellow)
        )
        controller.view.tintColor = .magenta

        // When the Continue button is enabled
        controller.scrolledToBottom = true
        let button = try XCTUnwrap(buttons(in: controller.view).first)
        let label = try XCTUnwrap(button.subviews.compactMap { $0 as? UILabel }.first)

        // Then the button uses both supplied colors
        XCTAssertEqual(button.backgroundColor, .purple)
        XCTAssertEqual(label.textColor, .yellow)
    }

    func testCustomContinueButtonDynamicColors() throws {
        // Given dynamic button colors and a custom app tint
        let controller = try makeViewController(
            primaryButtonStyle: .custom(
                backgroundColor: .dynamic(light: .black, dark: .white),
                textColor: .dynamic(light: .white, dark: .black)
            )
        )
        controller.view.tintColor = .magenta
        controller.scrolledToBottom = true
        let consentButtons = buttons(in: controller.view)
        let button = try XCTUnwrap(consentButtons.first)
        let label = try XCTUnwrap(button.subviews.compactMap { $0 as? UILabel }.first)

        // When the same button's colors resolve in light and dark mode
        for style: UIUserInterfaceStyle in [.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)

            // Then the background and text use opposite black and white colors
            XCTAssertEqual(button.backgroundColor?.resolvedColor(with: traits), style == .dark ? .white : .black)
            XCTAssertEqual(label.textColor.resolvedColor(with: traits), style == .dark ? .black : .white)
        }

        // ...and the decline button keeps its standard appearance
        let declineButton = try XCTUnwrap(consentButtons.last)
        let declineLabel = try XCTUnwrap(declineButton.subviews.compactMap { $0 as? UILabel }.first)
        XCTAssertEqual(declineLabel.textColor, .magenta)
        XCTAssertEqual(declineButton.backgroundColor, .secondarySystemFill)
    }

    func testCustomContinueButtonIsDisabledUntilScrolled() throws {
        // Given unread consent with custom button colors
        let controller = try makeViewController(
            primaryButtonStyle: .custom(backgroundColor: .purple, textColor: .yellow)
        )
        let button = try XCTUnwrap(buttons(in: controller.view).first)
        let label = try XCTUnwrap(button.subviews.compactMap { $0 as? UILabel }.first)
        XCTAssertFalse(button.isEnabled)
        for style: UIUserInterfaceStyle in [.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            XCTAssertEqual(button.backgroundColor?.resolvedColor(with: traits), UIColor.systemGray4.resolvedColor(with: traits))
            XCTAssertEqual(label.textColor.resolvedColor(with: traits), UIColor.systemGray.resolvedColor(with: traits))
        }

        // When the user finishes reading and continues
        controller.scrolledToBottom = true
        XCTAssertTrue(button.isEnabled)
        controller.flowViewModel.buttons.first?.didTap()

        // Then consent is saved as usual
        XCTAssertEqual(mockSheetController.savedData?.biometricConsent, true)
    }

    private func makeViewController(
        configuration: IdentityVerificationSheet.Configuration.BiometricConsentConfiguration? = nil,
        primaryButtonStyle: IdentityVerificationSheet.Configuration.PrimaryButtonStyle = .default
    ) throws -> BiometricConsentViewController {
        var sheetConfiguration = IdentityVerificationSheet.Configuration(brandLogo: UIImage())
        sheetConfiguration.primaryButtonStyle = primaryButtonStyle
        mockSheetController = VerificationSheetControllerMock(
            flowController: VerificationSheetFlowController(configuration: sheetConfiguration)
        )
        return try BiometricConsentViewController(
            brandLogo: UIImage(),
            showsStripeLogo: !Self.mockVerificationPage.isStripe,
            consentContent: Self.mockVerificationPage.biometricConsent,
            configuration: configuration,
            sheetController: mockSheetController
        )
    }

    private func buttons(in view: UIView) -> [Button] {
        return view.subviews.flatMap { subview in
            if let button = subview as? Button {
                return [button]
            }
            return buttons(in: subview)
        }
    }
}
