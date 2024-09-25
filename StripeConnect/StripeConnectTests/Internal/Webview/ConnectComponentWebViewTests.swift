//
//  ConnectComponentWebViewTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/20/24.
//

import Foundation
import SafariServices
@_spi(PrivateBetaConnect) @testable import StripeConnect
@_spi(STP) import StripeCore
import WebKit
import XCTest

class ConnectComponentWebViewTests: XCTestCase {

    typealias FontSource = EmbeddedComponentManager.CustomFontSource

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
            {"appearance":{"variables":{"actionPrimaryColorText":"rgb(255, 255, 255)","fontFamily":"-apple-system","fontSizeBase":"16px"}},"fonts":[],"locale":"fr-FR"}
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

    func componentManagerAssertingOnFetch(appearance: Appearance = .default, fonts: [EmbeddedComponentManager.CustomFontSource] = []) -> EmbeddedComponentManager {
        EmbeddedComponentManager(apiClient: .init(publishableKey: "test"),
                                 appearance: appearance,
                                 fonts: fonts,
                                 fetchClientSecret: {
            XCTFail("Client secret should not be retrieved in this test")
            return ""
        })
    }

    @MainActor
    func testFetchInitParamsWithFontSource() async throws {
        let testBundle = Bundle(for: type(of: self))
        let fileURL = try XCTUnwrap(testBundle.url(forResource: "FakeFont", withExtension: "txt"))
        let fontSource = try FontSource(font: .systemFont(ofSize: 12), fileUrl: fileURL)
        let componentManager = componentManagerAssertingOnFetch(fonts: [fontSource])
        let webView = ConnectComponentWebView(componentManager: componentManager,
                                              componentType: .payouts,
                                              webLocale: Locale(identifier: "fr_FR"),
                                              loadContent: false)

       try await webView.evaluateMessageWithReply(name: "fetchInitParams",
                                                  json: "{}",
                                                  expectedResponse: """
                                                            {"appearance":{"variables":{"fontFamily":"-apple-system","fontSizeBase":"16px"}},"fonts":[{"family":".AppleSystemUIFont","src":"url(data:font\\/txt;charset=utf-8;base64,dGVzdAo=)","weight":"400"}],"locale":"fr-FR"}
                                                            """)
    }

    @MainActor
    func testLogout() async throws {
        let componentManager = componentManagerAssertingOnFetch()

        let webView = ConnectComponentWebView(componentManager: componentManager,
                                              componentType: .payouts,
                                              webLocale: Locale(identifier: "fr_FR"),
                                              loadContent: false)

        let expectation = try webView.expectationForMessageReceived(sender: LogoutSender())
        componentManager.logout()
        await fulfillment(of: [expectation], timeout: TestHelpers.defaultTimeout)
    }
}
