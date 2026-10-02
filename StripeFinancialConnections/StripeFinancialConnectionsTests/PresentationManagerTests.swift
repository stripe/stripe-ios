//
//  PresentationManagerTests.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-01-30.
//

@testable @_spi(STP) import StripeFinancialConnections
import UIKit
import XCTest

class PresentationManagerTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        PresentationManager.shared.configuration = .init()
        PresentationManager.shared.setAuthenticatedLinkBrand(nil)
    }

    func testConfigurationIsApplied() {
        let toViewController = UIViewController()

        // Start the user interface style as `.light`
        toViewController.overrideUserInterfaceStyle = .light
        XCTAssertEqual(toViewController.traitCollection.userInterfaceStyle, .light)

        // Create an `.alwaysDark` configuration
        var configuration = FinancialConnectionsSheet.Configuration()
        configuration.style = .alwaysDark
        PresentationManager.shared.configuration = configuration

        // Expect that the presentation manager sets the user interface style as `.dark`
        PresentationManager.shared.present(toViewController, from: UIViewController())
        XCTAssertEqual(toViewController.traitCollection.userInterfaceStyle, .dark)
    }

    func testLinkThemeUsesColoredLinkLogos() {
        let appearance = FinancialConnectionsAppearance(theme: .linkLight, linkBrand: .link)

        XCTAssertEqual(appearance.logo, .link_logo_color)
        XCTAssertEqual(appearance.darkModeLogo, .link_logo_color_dark)
        XCTAssertEqual(appearance.logoImage(for: .light).renderingMode, .alwaysOriginal)
        XCTAssertEqual(appearance.logoImage(for: .dark).renderingMode, .alwaysOriginal)
    }

    func testLinkThemeUsesColoredOnelinkLogos() {
        let appearance = FinancialConnectionsAppearance(theme: .linkLight, linkBrand: .onelink)

        XCTAssertEqual(appearance.logo, .onelink_logo_color)
        XCTAssertEqual(appearance.darkModeLogo, .onelink_logo_color_dark)
        XCTAssertEqual(appearance.logoImage(for: .light).renderingMode, .alwaysOriginal)
        XCTAssertEqual(appearance.logoImage(for: .dark).renderingMode, .alwaysOriginal)
    }

    func testConfiguredOnelinkBrandOverridesManifestLinkBrand() {
        var configuration = FinancialConnectionsSheet.Configuration()
        configuration.linkBrand = .onelink
        PresentationManager.shared.configuration = configuration

        let appearance = FinancialConnectionsAppearance(theme: .linkLight, linkBrand: .link)

        XCTAssertEqual(appearance.logo, .onelink_logo_color)
        XCTAssertEqual(appearance.darkModeLogo, .onelink_logo_color_dark)
    }

    func testStripeThemeUsesTintedStripeLogo() {
        let appearance = FinancialConnectionsAppearance(theme: .light, linkBrand: nil)

        XCTAssertEqual(appearance.logo, .stripe_logo)
        XCTAssertNil(appearance.darkModeLogo)
        XCTAssertEqual(appearance.logoImage(for: .light).renderingMode, .alwaysTemplate)
    }
}
