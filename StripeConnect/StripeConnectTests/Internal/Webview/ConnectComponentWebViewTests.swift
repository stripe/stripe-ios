//
//  ConnectComponentWebViewTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/20/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(PrivateBetaConnect) @testable import StripeConnect
import XCTest
import WebKit
import SafariServices

class ConnectComponentWebViewTests: XCTestCase {
    func testSetup() {
        let componentManager = EmbeddedComponentManager(apiClient: .init(publishableKey: "test"), fetchClientSecret: {
            XCTFail("Client secret should not be retrieved in this test")
            return ""
        })
        let webView = ConnectComponentWebView(componentManager: componentManager, componentType: .payouts)
        
        XCTAssertEqual(webView.url, URL(string: "https://connect-js.stripe.com/v1.0/ios_webview.html#component=payouts&publicKey=test"))
    }
    
    @MainActor
    func testFetchClientSecret() async throws {
        let expectation = XCTestExpectation(description: "Client secret is fetched")
        let componentManager = EmbeddedComponentManager(apiClient: .init(publishableKey: "test"), fetchClientSecret: {
            expectation.fulfill()
            return ""
        })
        let webView = ConnectComponentWebView(componentManager: componentManager, componentType: .payouts)
        
        try await webView.evaluateMessageWithReply(name: "fetchClientSecret",
                                                   json: "{}",
                                                   postReply: false)
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    @MainActor
    func testLocale() async throws {
        let componentManager = EmbeddedComponentManager(apiClient: .init(publishableKey: "test"), fetchClientSecret: {
            XCTFail("Client secret should not be retrieved in this test")
            return ""
        })
        let notificationCenter = NotificationCenter()
        let webView = ConnectComponentWebView(
            componentManager: componentManager,
            componentType: .payouts,
            notificationCenter: notificationCenter,
            webLocale: Locale(identifier: "fr_FR"))
        
        let expectation = try webView.expectationForMessageReceived(sender: UpdateConnectInstanceSender(payload: .init(locale: "fr-FR")))
        
        notificationCenter.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
}
