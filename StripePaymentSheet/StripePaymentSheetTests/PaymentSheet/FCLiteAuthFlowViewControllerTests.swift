//
//  FCLiteAuthFlowViewControllerTests.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-19.
//

import Foundation
@testable import StripePaymentSheet
import XCTest

class FCLiteAuthFlowViewControllerTests: XCTestCase {
    private static let baseAuthFlowUrlString: String = "https://auth.stripe.com/link-accounts"
    private static var baseAuthFlowUrl: URL {
        URL(string: Self.baseAuthFlowUrlString)!
    }

    func testHostedAuthUrl_notInstantDebits() {
        let manifest = mockManifest(isInstantDebits: false)
        let hostedAuthUrl = FCLiteAuthFlowViewController.hostedAuthUrl(from: manifest)
        XCTAssertEqual(hostedAuthUrl, Self.baseAuthFlowUrl)
    }

    func testHostedAuthUrl_instantDebits() {
        let manifest = mockManifest(isInstantDebits: true)
        let hostedAuthUrl = FCLiteAuthFlowViewController.hostedAuthUrl(from: manifest)
        let expectedAuthFlowUrlString = Self.baseAuthFlowUrlString + "&return_payment_method=true&expand_payment_method=true"
        XCTAssertEqual(hostedAuthUrl, URL(string: expectedAuthFlowUrlString))
    }

    func testHostedAuthUrl_complexBaseUrl() {
        let complexBaseUrlString = Self.baseAuthFlowUrlString + "?apiKey=pk_test_123&"
        let manifest = mockManifest(hostedAuthURL: URL(string: complexBaseUrlString)!)
        let hostedAuthUrl = FCLiteAuthFlowViewController.hostedAuthUrl(from: manifest)
        let expectedAuthFlowUrlString = complexBaseUrlString + "return_payment_method=true&expand_payment_method=true"
        XCTAssertEqual(hostedAuthUrl, URL(string: expectedAuthFlowUrlString))
    }

    private func mockManifest(
        isInstantDebits: Bool = true,
        hostedAuthURL: URL = FCLiteAuthFlowViewControllerTests.baseAuthFlowUrl
    ) -> LinkAccountSessionManifest {
        LinkAccountSessionManifest(
            id: "id",
            hostedAuthURL: hostedAuthURL,
            successURL: URL(string: "stripe://success_url")!,
            cancelURL: URL(string: "stripe://cancel_url")!,
            product: isInstantDebits ? "instant_debits" : "something_else",
            manualEntryUsesMicrodeposits: false
        )
    }
}
