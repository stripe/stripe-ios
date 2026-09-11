//
//  IdentityFlowViewControllerTest.swift
//  StripeIdentityTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit
import XCTest

// swift-format-ignore
@_spi(STP) @testable import StripeIdentity

final class IdentityFlowViewControllerTest: XCTestCase {
    func testCustomPrimaryButtonStyleAcrossScreens() throws {
        // Given a flow configured with dynamic primary button colors
        var configuration = IdentityVerificationSheet.Configuration(brandLogo: UIImage())
        configuration.primaryButtonStyle = .custom(
            backgroundColor: .dynamic(light: .black, dark: .white),
            textColor: .dynamic(light: .white, dark: .black)
        )
        let sheetController = VerificationSheetControllerMock(
            flowController: VerificationSheetFlowController(configuration: configuration)
        )
        let content = try VerificationPageMock.response200.make()

        // When subsequent pages use the same flow
        let controllers: [IdentityFlowViewController] = [
            try DocumentWarmupViewController(sheetController: sheetController, staticContent: content.documentSelect),
            try SelfieWarmupViewController(sheetController: sheetController),
            IndividualViewController(individualContent: content.individual, missing: [], sheetController: sheetController),
            SuccessViewController(successContent: content.success, sheetController: sheetController),
        ]

        // Then each page's primary button uses the configured colors in both appearances
        for controller in controllers {
            controller.view.tintColor = .magenta
            let button = try XCTUnwrap(buttons(in: controller.view).first)
            let label = try XCTUnwrap(button.subviews.compactMap { $0 as? UILabel }.first)
            XCTAssertTrue(button.isEnabled, "\(type(of: controller))")
            for style: UIUserInterfaceStyle in [.light, .dark] {
                let traits = UITraitCollection(userInterfaceStyle: style)
                XCTAssertEqual(button.backgroundColor?.resolvedColor(with: traits), style == .dark ? .white : .black, "\(type(of: controller))")
                XCTAssertEqual(label.textColor.resolvedColor(with: traits), style == .dark ? .black : .white, "\(type(of: controller))")
            }
        }
    }

    func testCustomPrimaryButtonColorsAcrossSubmissionStates() throws {
        // Given a primary button styled at the flow level
        var configuration = IdentityVerificationSheet.Configuration(brandLogo: UIImage())
        configuration.primaryButtonStyle = .custom(backgroundColor: .purple, textColor: .yellow)
        let sheetController = VerificationSheetControllerMock(
            flowController: VerificationSheetFlowController(configuration: configuration)
        )
        let controller = IdentityFlowViewController(sheetController: sheetController, analyticsScreenName: .individual)
        let contentView = UIView()

        // When a submission starts and finishes, then input becomes invalid and valid again
        for state: IdentityFlowView.ViewModel.Button.State in [.enabled, .loading, .enabled, .disabled, .enabled] {
            controller.configure(
                backButtonTitle: nil,
                viewModel: .init(
                    headerViewModel: nil,
                    contentView: contentView,
                    buttons: [.continueButton(state: state, didTap: {})]
                )
            )
            let button = try XCTUnwrap(buttons(in: controller.view).first)
            let label = try XCTUnwrap(button.subviews.compactMap { $0 as? UILabel }.first)
            let spinner = try XCTUnwrap(button.subviews.compactMap { $0 as? ActivityIndicator }.first)
            XCTAssertEqual(button.isEnabled, state == .enabled)
            XCTAssertEqual(button.isLoading, state == .loading)

            // Then custom colors apply while enabled
            // ...and loading and disabled states retain the existing gray appearance, including the spinner
            for style: UIUserInterfaceStyle in [.light, .dark] {
                let traits = UITraitCollection(userInterfaceStyle: style)
                let expectedBackground: UIColor = state == .enabled ? .purple : .systemGray4
                let expectedForeground: UIColor = state == .enabled ? .yellow : .systemGray
                XCTAssertEqual(button.backgroundColor?.resolvedColor(with: traits), expectedBackground.resolvedColor(with: traits))
                XCTAssertEqual(label.textColor.resolvedColor(with: traits), expectedForeground.resolvedColor(with: traits))
                XCTAssertEqual(spinner.tintColor.resolvedColor(with: traits), expectedForeground.resolvedColor(with: traits))
            }
        }
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
