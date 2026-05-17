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
        PresentationManager.shared.consumerLinkBrand = nil
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

        let appearance = FinancialConnectionsAppearance(theme: .light, brand: nil)

        XCTAssertEqual(appearance.logo, .onelink_logo)
    }

    func testConsumerSessionBrandOverridesManifestBrandForAppearanceResolution() {
        PresentationManager.shared.consumerLinkBrand = .onelink

        let appearance = FinancialConnectionsAppearance(theme: .light, brand: .link)

        XCTAssertEqual(appearance.logo, .onelink_logo)
    }

    func testOnelinkBrandUsesSameTintAsLinkForLightTheme() {
        let onelinkAppearance = FinancialConnectionsAppearance(theme: .light, brand: .onelink)
        let linkAppearance = FinancialConnectionsAppearance(theme: .light, brand: .link)

        XCTAssertTrue(onelinkAppearance.logoTintColor.isEqual(linkAppearance.logoTintColor))
    }

    func testOnelinkBrandUsesSameTintAsLinkForLinkTheme() {
        let onelinkAppearance = FinancialConnectionsAppearance(theme: .linkLight, brand: .onelink)
        let linkAppearance = FinancialConnectionsAppearance(theme: .linkLight, brand: .link)

        XCTAssertTrue(onelinkAppearance.logoTintColor.isEqual(linkAppearance.logoTintColor))
    }

    func testSetConsumerLinkBrandSetsWhenVerifiedWithBrand() throws {
        let session = try makeConsumerSession(smsState: "VERIFIED", brand: "link")
        PresentationManager.shared.setConsumerLinkBrand(from: session)
        XCTAssertEqual(PresentationManager.shared.consumerLinkBrand, .link)
    }

    func testSetConsumerLinkBrandDoesNotClearWhenSessionIsUnverified() throws {
        // Simulate prior confirm_verification having set the brand.
        PresentationManager.shared.consumerLinkBrand = .onelink

        // Simulate startVerificationSession returning an unverified (STARTED) session.
        let startedSession = try makeConsumerSession(smsState: "STARTED", brand: "link")
        PresentationManager.shared.setConsumerLinkBrand(from: startedSession)

        // The brand from the prior confirm_verification must be preserved.
        XCTAssertEqual(PresentationManager.shared.consumerLinkBrand, .onelink)
    }

    func testSetConsumerLinkBrandDoesNotClearWhenSessionHasNoBrand() throws {
        PresentationManager.shared.consumerLinkBrand = .link

        let verifiedNoBrandSession = try makeConsumerSession(smsState: "VERIFIED", brand: nil)
        PresentationManager.shared.setConsumerLinkBrand(from: verifiedNoBrandSession)

        XCTAssertEqual(PresentationManager.shared.consumerLinkBrand, .link)
    }

    func testResetConsumerLinkBrandClearsBrand() {
        PresentationManager.shared.consumerLinkBrand = .link
        PresentationManager.shared.resetConsumerLinkBrand()
        XCTAssertNil(PresentationManager.shared.consumerLinkBrand)
    }

    func testLinkBrandStillUsesThemeTinting() {
        let linkAppearance = FinancialConnectionsAppearance(theme: .light, brand: .link)
        let stripeAppearance = FinancialConnectionsAppearance(theme: .light, brand: nil)

        XCTAssertFalse(linkAppearance.logoTintColor.isEqual(UIColor.clear))
        XCTAssertFalse(stripeAppearance.logoTintColor.isEqual(UIColor.clear))
    }
}

private func makeConsumerSession(smsState: String, brand: String?) throws -> ConsumerSessionData {
    var json: [String: Any] = [
        "clientSecret": "cs_test",
        "emailAddress": "test@example.com",
        "redactedFormattedPhoneNumber": "+1 (***) *** 1234",
        "verificationSessions": [["type": "SMS", "state": smsState]],
    ]
    if let brand {
        json["link_brand"] = brand
    }
    let data = try JSONSerialization.data(withJSONObject: json)
    return try JSONDecoder().decode(ConsumerSessionData.self, from: data)
}
