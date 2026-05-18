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

    func testLinkBrandOverrideIsAvailableToAppearanceResolution() {
        var configuration = FinancialConnectionsSheet.Configuration()
        configuration.linkBrand = .onelink
        PresentationManager.shared.configuration = configuration

        let appearance = FinancialConnectionsAppearance(theme: .light, linkBrand: nil)

        XCTAssertEqual(appearance.logo, .onelink_logo)
    }

    func testAuthenticatedLinkBrandOverridesManifestBrand() {
        PresentationManager.shared.setAuthenticatedLinkBrand(.onelink)

        let appearance = FinancialConnectionsAppearance(theme: .light, linkBrand: .link)

        XCTAssertEqual(appearance.logo, .onelink_logo)
    }

    func testConfigurationLinkBrandOverridesAuthenticatedLinkBrand() {
        var configuration = FinancialConnectionsSheet.Configuration()
        configuration.linkBrand = .link
        PresentationManager.shared.configuration = configuration
        PresentationManager.shared.setAuthenticatedLinkBrand(.onelink)

        let appearance = FinancialConnectionsAppearance(theme: .light, linkBrand: nil)

        XCTAssertEqual(appearance.logo, .link_logo)
    }

    func testOnelinkBrandUsesSameTintAsLinkForLightTheme() {
        let onelinkAppearance = FinancialConnectionsAppearance(theme: .light, linkBrand: .onelink)
        let linkAppearance = FinancialConnectionsAppearance(theme: .light, linkBrand: .link)

        XCTAssertTrue(onelinkAppearance.logoTintColor.isEqual(linkAppearance.logoTintColor))
    }

    func testOnelinkBrandUsesSameTintAsLinkForLinkTheme() {
        let onelinkAppearance = FinancialConnectionsAppearance(theme: .linkLight, linkBrand: .onelink)
        let linkAppearance = FinancialConnectionsAppearance(theme: .linkLight, linkBrand: .link)

        XCTAssertTrue(onelinkAppearance.logoTintColor.isEqual(linkAppearance.logoTintColor))
    }

    func testLinkBrandStillUsesThemeTinting() {
        let linkAppearance = FinancialConnectionsAppearance(theme: .light, linkBrand: .link)
        let stripeAppearance = FinancialConnectionsAppearance(theme: .light, linkBrand: nil)

        XCTAssertFalse(linkAppearance.logoTintColor.isEqual(UIColor.clear))
        XCTAssertFalse(stripeAppearance.logoTintColor.isEqual(UIColor.clear))
    }
}
