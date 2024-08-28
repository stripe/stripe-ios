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
    @MainActor
    func testFetchClientSecret() async throws {
        let componentManager = EmbeddedComponentManager(apiClient: .init(publishableKey: "test"), fetchClientSecret: {
            return "test"
        })
        let webView = ConnectComponentWebView(componentManager: componentManager, componentType: .payouts, loadContent: false)
        
        try await webView.evaluateMessageWithReply(name: "fetchClientSecret",
                                                   json: "{}",
                                                   expectedResponse: "test")
    }
    
    @MainActor
    func testFetchInitParams() async throws {
        let message = FetchInitParamsMessageHandler.Reply(locale: "fr-FR", appearance: .default)
        let componentManager = componentManagerAssertingOnFetch()
        let webView = ConnectComponentWebView(componentManager: componentManager,
                                              componentType: .payouts,
                                              webLocale: Locale(identifier: "fr_FR"),
                                              loadContent: false)
        
        
       try await webView.evaluateMessageWithReply(name: "fetchInitParams",
                                                                json: "{}",
                                                                expectedResponse: message)
    }
    
    @MainActor
    func testUpdateAppearance() async throws {
        let componentManager = componentManagerAssertingOnFetch()
        let webView = ConnectComponentWebView(componentManager: componentManager,
                                              componentType: .payouts,
                                              webLocale: Locale(identifier: "fr_FR"),
                                              loadContent: false)
        var appearance = EmbeddedComponentManager.Appearance()
        appearance.spacingUnit = 5
        let expectation = try webView.expectationForMessageReceived(sender: UpdateConnectInstanceSender(payload: .init(locale: "fr-FR", appearance: .init(appearance: appearance, traitCollection: UITraitCollection()))))
        componentManager.update(appearance: appearance)
       
        // Ensures the appearance on component manager was set.
        XCTAssertEqual(appearance.asDictionary(traitCollection: .init()), componentManager.appearance.asDictionary(traitCollection: .init()))
        
        await fulfillment(of: [expectation], timeout: TestHelpers.defaultTimeout)
    }
    
    @MainActor
    func testFetchInitParamsTraitCollection() async throws {
        var appearance = EmbeddedComponentManager.Appearance()
        appearance.colors.actionPrimaryText = UIColor { $0.userInterfaceStyle == .light ? .black : .white }

        let componentManager = componentManagerAssertingOnFetch(appearance: appearance)
        
        let webView = ConnectComponentWebView(componentManager: componentManager,
                                              componentType: .payouts,
                                              webLocale: Locale(identifier: "fr_FR"),
                                              loadContent: false)

        webView.triggerTraitCollectionChange(style: .dark)
        
        try await webView.evaluateMessageWithReply(name: "fetchInitParams",
                                                   json: "{}",
                                                   expectedResponse: """
            {"appearance":{"variables":{"actionPrimaryColorText":"rgb(255, 255, 255)","fontFamily":"-apple-system"}},"fonts":[],"locale":"fr-FR"}
            """)
    }
    
    @MainActor
    func testUpdateTraitCollection() async throws {
        var appearance = EmbeddedComponentManager.Appearance()
        appearance.colors.actionPrimaryText = UIColor { $0.userInterfaceStyle == .light ? .red : .green }

        let componentManager = componentManagerAssertingOnFetch(appearance: appearance)
        
        let webView = ConnectComponentWebView(componentManager: componentManager,
                                              componentType: .payouts,
                                              webLocale: Locale(identifier: "fr_FR"),
                                              loadContent: false)

        let expectation = try webView.expectationForMessageReceived(sender: UpdateConnectInstanceSender(payload: .init(locale: "fr-FR", appearance: .init(appearance: appearance, traitCollection: UITraitCollection(userInterfaceStyle: .dark)))))

        webView.triggerTraitCollectionChange(style: .dark)
        
        await fulfillment(of: [expectation], timeout: TestHelpers.defaultTimeout)
    }
    
    @MainActor
    func testLocale() async throws {
        let componentManager = componentManagerAssertingOnFetch()
        let notificationCenter = NotificationCenter()
        let webView = ConnectComponentWebView(
            componentManager: componentManager,
            componentType: .payouts,
            notificationCenter: notificationCenter,
            webLocale: Locale(identifier: "fr_FR"),
            loadContent: false)
        
        let expectation = try webView.expectationForMessageReceived(sender: UpdateConnectInstanceSender(payload: .init(locale: "fr-FR", appearance: .default)))
        
        notificationCenter.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)
        
        await fulfillment(of: [expectation], timeout: TestHelpers.defaultTimeout)
    }
    
    func componentManagerAssertingOnFetch(appearance: Appearance = .default) -> EmbeddedComponentManager {
        EmbeddedComponentManager(apiClient: .init(publishableKey: "test"),
                                 appearance: appearance,
                                 fetchClientSecret: {
            XCTFail("Client secret should not be retrieved in this test")
            return ""
        })
    }
}
