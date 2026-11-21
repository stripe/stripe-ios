//
//  TestBackendTests.swift
//  PaymentSheetUITest
//
//  Unit tests of Example/Shared/TestBackends.swift; they don't launch the app.
//

import XCTest

class TestBackendTests: XCTestCase {
    private let vercelURL = "https://stripe-mobile-example-ci-backends.vercelapp.stripe.dev/"

    func testDefaultsToTheVercelDeploymentWithItsPublicBypass() {
        // When no variables are set
        // Then each backend is under the Vercel deployment, with its public bypass
        XCTAssertEqual(TestBackend.playground.baseURL(environment: [:]), vercelURL + "playground")
        XCTAssertEqual(TestBackend.bypass(environment: [:]), "PublicAvailableiOSAndroidBackend")
    }

    func testURLVariableOverridesTheDeployment() {
        // Given another root, without a trailing slash
        let environment = ["STRIPE_TEST_BACKENDS_URL": "https://other.example.com"]

        // Then backends are under it
        XCTAssertEqual(
            TestBackend.iosFinancialConnectionsPlayground.baseURL(environment: environment),
            "https://other.example.com/ios-financial-connections-playground"
        )
        XCTAssertEqual(TestBackend.bypass(environment: environment), "PublicAvailableiOSAndroidBackend")
    }

    func testLocalBackendsGetABypassOnlyFromTheVariable() {
        // Given a local copy of the backends
        let local = ["STRIPE_TEST_BACKENDS_URL": "http://127.0.0.1:4567/"]

        // Then there's no bypass, and web view URLs are unchanged
        XCTAssertNil(TestBackend.bypass(environment: local))
        let page = URL(string: "http://127.0.0.1:4567/connections-webview/")!
        XCTAssertEqual(TestBackend.addingBypass(to: page, environment: local), page)

        // ...unless the bypass variable is set
        var withBypass = local
        withBypass["STRIPE_TEST_BACKENDS_BYPASS"] = "other-bypass"
        XCTAssertEqual(TestBackend.bypass(environment: withBypass), "other-bypass")
    }

    func testWebViewURLsCarryTheBypassAndAskForTheCookie() {
        // When a web view's first page is loaded from the deployment
        let page = URL(string: vercelURL + "connections-webview/")!
        let url = TestBackend.addingBypass(to: page, environment: [:])

        // Then the URL carries the bypass and asks Vercel for its cookie
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(items, [
            URLQueryItem(name: "x-vercel-protection-bypass", value: "PublicAvailableiOSAndroidBackend"),
            URLQueryItem(name: "x-vercel-set-bypass-cookie", value: "true"),
        ])
    }

    func testURLProtocolAddsTheBypassOnlyToTestBackendRequests() throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment[TestBackend.urlEnvironmentKey] != nil,
            "Uses the default root"
        )
        // Given requests for a backend, for another host, and one that already has the bypass
        let backend = URLRequest(url: TestBackend.playground.url.appendingPathComponent("checkout"))
        let other = URLRequest(url: URL(string: "https://api.stripe.com/v1/payment_intents")!)
        var alreadyBypassed = backend
        alreadyBypassed.setValue("PublicAvailableiOSAndroidBackend", forHTTPHeaderField: TestBackend.bypassHeader)

        // Then only the backend request without the bypass goes through TestBackendsURLProtocol
        XCTAssertTrue(TestBackendsURLProtocol.canInit(with: backend))
        XCTAssertFalse(TestBackendsURLProtocol.canInit(with: other))
        XCTAssertFalse(TestBackendsURLProtocol.canInit(with: alreadyBypassed))
    }
}
