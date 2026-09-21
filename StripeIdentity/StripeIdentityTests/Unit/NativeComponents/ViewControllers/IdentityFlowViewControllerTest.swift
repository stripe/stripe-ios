//
//  IdentityFlowViewControllerTest.swift
//  StripeIdentityTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit
import XCTest

@_spi(STP) @testable import StripeIdentity

final class IdentityFlowViewControllerTest: XCTestCase {
    func testCustomPrimaryButtonStyleAcrossScreens() throws {
        // Given a flow configured with dynamic primary button colors and a minimum height
        var configuration = IdentityVerificationSheet.Configuration(brandLogo: UIImage())
        configuration.primaryButtonStyle = .custom(
            backgroundColor: .dynamic(light: .black, dark: .white),
            textColor: .dynamic(light: .white, dark: .black),
            height: 52
        )
        let sheetController = VerificationSheetControllerMock(
            flowController: VerificationSheetFlowController(configuration: configuration)
        )
        let content = try VerificationPageMock.response200.make()

        // When subsequent pages use the same flow
        let controllers: [IdentityFlowViewController] = [
            try DocumentWarmupViewController(sheetController: sheetController, staticContent: content.documentSelect),
            try SelfieWarmupViewController(sheetController: sheetController),
            IndividualViewController(
                individualContent: content.individual,
                missing: [],
                sheetController: sheetController
            ),
            SuccessViewController(successContent: content.success, sheetController: sheetController),
        ]

        // Then each page's primary button uses the configured colors in both appearances
        for controller in controllers {
            controller.view.tintColor = .magenta
            let button = try XCTUnwrap(buttons(in: controller.view).first)
            let label = try XCTUnwrap(button.subviews.compactMap { $0 as? UILabel }.first)
            XCTAssertTrue(button.isEnabled, "\(type(of: controller))")
            XCTAssertEqual(button.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height, 52)
            for style: UIUserInterfaceStyle in [.light, .dark] {
                let traits = UITraitCollection(userInterfaceStyle: style)
                XCTAssertEqual(
                    button.backgroundColor?.resolvedColor(with: traits),
                    style == .dark ? .white : .black,
                    "\(type(of: controller))"
                )
                XCTAssertEqual(
                    label.textColor.resolvedColor(with: traits),
                    style == .dark ? .black : .white,
                    "\(type(of: controller))"
                )
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
                XCTAssertEqual(
                    button.backgroundColor?.resolvedColor(with: traits),
                    expectedBackground.resolvedColor(with: traits)
                )
                XCTAssertEqual(
                    label.textColor.resolvedColor(with: traits),
                    expectedForeground.resolvedColor(with: traits)
                )
                XCTAssertEqual(
                    spinner.tintColor.resolvedColor(with: traits),
                    expectedForeground.resolvedColor(with: traits)
                )
            }
        }
    }

    func testDefaultAndNilCustomHeightsPreserveIntrinsicHeight() throws {
        // Given primary and secondary buttons with default styles
        let flowView = IdentityFlowView()
        let viewModel = IdentityFlowView.ViewModel(
            headerViewModel: nil,
            contentView: UIView(),
            buttons: [
                .continueButton(didTap: {}),
                .init(text: "Secondary", isPrimary: false, didTap: {}),
            ]
        )

        // When the default styles are applied
        try flowView.configure(with: viewModel)
        let defaultButtons = buttons(in: flowView)

        // Then both buttons keep their intrinsic height
        XCTAssertEqual(defaultButtons.count, 2)
        XCTAssertEqual(defaultButtons[0].systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height, 44)
        XCTAssertEqual(defaultButtons[1].systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height, 44)

        // When custom colors are applied without heights
        try flowView.configure(
            with: viewModel,
            primaryButtonStyle: .custom(backgroundColor: .purple, textColor: .yellow, height: nil),
            secondaryButtonStyle: .custom(backgroundColor: .orange, textColor: .blue, height: nil)
        )

        // Then both buttons still keep their intrinsic height
        let customButtons = buttons(in: flowView)
        XCTAssertEqual(customButtons[0].systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height, 44)
        XCTAssertEqual(customButtons[1].systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height, 44)
    }

    func testRepeatedConfigurationUpdatesReplaceMinimumHeightConstraints() throws {
        // Given a flow with primary and secondary buttons
        let flowView = IdentityFlowView()
        let viewModel = IdentityFlowView.ViewModel(
            headerViewModel: nil,
            contentView: UIView(),
            buttons: [
                .continueButton(didTap: {}),
                .init(text: "Secondary", isPrimary: false, didTap: {}),
            ]
        )

        // When styles and states are repeatedly updated
        for state: IdentityFlowView.ViewModel.Button.State in [.enabled, .loading, .disabled, .enabled] {
            let updatedViewModel = IdentityFlowView.ViewModel(
                headerViewModel: nil,
                contentView: UIView(),
                buttons: [
                    .continueButton(state: state, didTap: {}),
                    .init(text: "Secondary", state: state, isPrimary: false, didTap: {}),
                ]
            )
            try flowView.configure(
                with: updatedViewModel,
                primaryButtonStyle: .custom(backgroundColor: .purple, textColor: .yellow, height: 52),
                secondaryButtonStyle: .custom(backgroundColor: .orange, textColor: .blue, height: nil)
            )
        }

        // Then only the primary button has one minimum-height constraint
        var configuredButtons = buttons(in: flowView)
        XCTAssertEqual(minimumHeightConstraints(in: configuredButtons[0]).map(\.constant), [52])
        XCTAssertTrue(minimumHeightConstraints(in: configuredButtons[1]).isEmpty)

        // When the customized height moves to the secondary style
        try flowView.configure(
            with: viewModel,
            primaryButtonStyle: .custom(backgroundColor: .purple, textColor: .yellow, height: nil),
            secondaryButtonStyle: .custom(backgroundColor: .orange, textColor: .blue, height: 52)
        )

        // Then the primary constraint is removed and the secondary receives one constraint
        configuredButtons = buttons(in: flowView)
        XCTAssertTrue(minimumHeightConstraints(in: configuredButtons[0]).isEmpty)
        XCTAssertEqual(minimumHeightConstraints(in: configuredButtons[1]).map(\.constant), [52])
    }

    private func buttons(in view: UIView) -> [Button] {
        return view.subviews.flatMap { subview in
            if let button = subview as? Button {
                return [button]
            }
            return buttons(in: subview)
        }
    }

    private func minimumHeightConstraints(in button: Button) -> [NSLayoutConstraint] {
        return button.constraints.filter {
            $0.firstAttribute == .height && $0.relation == .greaterThanOrEqual
        }
    }
}
