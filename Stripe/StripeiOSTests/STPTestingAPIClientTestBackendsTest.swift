//
//  STPTestingAPIClientTestBackendsTest.swift
//  StripeiOS Tests
//

import StripePaymentsTestUtils
import XCTest

class STPTestingAPIClientTestBackendsTest: XCTestCase {
    private let defaultURL = "https://stp-mobile-test-backends-764603794666.us-central1.run.app/"

    override func tearDown() {
        STPTestingAPIClient.usesDefaultTestBackendsURL = false
        super.tearDown()
    }

    func testDefaultsToTheCommittedDeployment() {
        // When no variables are set
        // Then the tests call the committed deployment
        XCTAssertEqual(STPTestingAPIClient.testBackendsURL(forEnvironment: [:]), defaultURL)
    }

    func testURLVariableOverridesTheDeploymentAndGetsATrailingSlash() {
        // Given another copy of the backends, such as a local server.py
        let environment = ["STRIPE_TEST_BACKENDS_URL": "http://127.0.0.1:4567"]

        // Then its URL is used, ending in a slash
        XCTAssertEqual(STPTestingAPIClient.testBackendsURL(forEnvironment: environment), "http://127.0.0.1:4567/")
    }

    func testRecordingAndPlaybackUseTheDeploymentTheRecordingsName() {
        // Given STPNetworkStubbingTestCase's playback
        STPTestingAPIClient.usesDefaultTestBackendsURL = true

        // When the URL variable names another copy
        let environment = ["STRIPE_TEST_BACKENDS_URL": "http://127.0.0.1:4567/"]

        // Then the recordings' URL is used anyway
        XCTAssertEqual(STPTestingAPIClient.testBackendsURL(forEnvironment: environment), defaultURL)
    }

    func testBackendURLAddsThePrefix() {
        // When a backend's URL is resolved
        let url = STPTestingAPIClient.testBackendURL(prefix: "ci-test-backend")

        // Then it's the root with the backend's prefix and a trailing slash
        XCTAssertEqual(url, STPTestingAPIClient.testBackendsURL + "ci-test-backend/")
    }
}
