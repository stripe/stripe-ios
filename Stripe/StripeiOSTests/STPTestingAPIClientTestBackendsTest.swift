//
//  STPTestingAPIClientTestBackendsTest.swift
//  StripeiOS Tests
//

import StripePaymentsTestUtils
import XCTest

class STPTestingAPIClientTestBackendsTest: XCTestCase {
    private let vercelURL = "https://stripe-mobile-example-ci-backends.vercelapp.stripe.dev/"
    private let publicBypass = ["x-vercel-protection-bypass": "PublicAvailableiOSAndroidBackend"]

    override func tearDown() {
        STPTestingAPIClient.usesDefaultTestBackendsURL = false
        super.tearDown()
    }

    func testDefaultsToTheVercelDeploymentWithItsPublicBypass() {
        // When no variables are set
        // Then the tests call the Vercel deployment with its public bypass
        XCTAssertEqual(STPTestingAPIClient.testBackendsURL(forEnvironment: [:]), vercelURL)
        XCTAssertEqual(STPTestingAPIClient.testBackendsHeaders(forEnvironment: [:]), publicBypass)
    }

    func testURLVariableOverridesTheDeploymentAndGetsATrailingSlash() {
        // Given another deployment
        let environment = ["STRIPE_TEST_BACKENDS_URL": "https://other.example.com"]

        // Then its URL is used, ending in a slash, with the public bypass
        XCTAssertEqual(STPTestingAPIClient.testBackendsURL(forEnvironment: environment), "https://other.example.com/")
        XCTAssertEqual(STPTestingAPIClient.testBackendsHeaders(forEnvironment: environment), publicBypass)
    }

    func testLocalBackendsGetABypassOnlyFromTheVariable() {
        // Given a local copy of the backends, which isn't behind Vercel
        let local = ["STRIPE_TEST_BACKENDS_URL": "http://127.0.0.1:4567/"]

        // Then requests carry no bypass
        XCTAssertEqual(STPTestingAPIClient.testBackendsHeaders(forEnvironment: local), [:])

        // ...and the bypass variable still applies
        var withBypass = local
        withBypass["STRIPE_TEST_BACKENDS_BYPASS"] = "other-bypass"
        XCTAssertEqual(
            STPTestingAPIClient.testBackendsHeaders(forEnvironment: withBypass),
            ["x-vercel-protection-bypass": "other-bypass"]
        )
    }

    func testRecordingAndPlaybackUseTheDeploymentTheRecordingsName() {
        // Given STPNetworkStubbingTestCase's playback
        STPTestingAPIClient.usesDefaultTestBackendsURL = true

        // When the URL variable names another copy
        let environment = ["STRIPE_TEST_BACKENDS_URL": "http://127.0.0.1:4567/"]

        // Then the recordings' Vercel URL is used anyway
        XCTAssertEqual(STPTestingAPIClient.testBackendsURL(forEnvironment: environment), vercelURL)
        XCTAssertEqual(STPTestingAPIClient.testBackendsHeaders(forEnvironment: environment), publicBypass)
    }

    func testBackendURLAddsThePrefix() {
        // When a backend's URL is resolved
        let url = STPTestingAPIClient.testBackendURL(prefix: "ci-test-backend")

        // Then it's the root with the backend's prefix and a trailing slash
        XCTAssertEqual(url, STPTestingAPIClient.testBackendsURL + "ci-test-backend/")
    }
}
