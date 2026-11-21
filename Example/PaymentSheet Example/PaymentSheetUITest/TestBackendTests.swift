//
//  TestBackendTests.swift
//  PaymentSheetUITest
//
//  Unit tests of Example/Shared/TestBackends.swift; they don't launch the app.
//

import XCTest

class TestBackendTests: XCTestCase {
    private let defaultURL = "https://stripe-mobile-example-ci-backends.vercelapp.stripe.dev/"

    func testDefaultsToTheCommittedDeployment() {
        // When no variables are set
        // Then each backend is under the committed deployment
        XCTAssertEqual(TestBackend.playground.baseURL(environment: [:]), defaultURL + "playground")
    }

    func testURLVariableOverridesTheDeployment() {
        // Given another root, without a trailing slash
        let environment = ["STRIPE_TEST_BACKENDS_URL": "http://127.0.0.1:4567"]

        // Then backends are under it
        XCTAssertEqual(
            TestBackend.iosFinancialConnectionsPlayground.baseURL(environment: environment),
            "http://127.0.0.1:4567/ios-financial-connections-playground"
        )
    }

    func testEmptyURLVariableFallsBackToTheDeployment() {
        // Given an empty variable, as an unset Bitrise env var gives
        let environment = ["STRIPE_TEST_BACKENDS_URL": ""]

        // Then the committed deployment is used
        XCTAssertEqual(TestBackend.rootURL(environment: environment), defaultURL)
    }
}
