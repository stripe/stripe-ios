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
    override func setUp() {
        super.setUp()
        ExperimentStore.shared.supportsDynamicStyle = true
    }

    override func tearDown() {
        super.tearDown()
        ExperimentStore.shared.reset()
        PresentationManager.shared.configuration = .init()
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
}
