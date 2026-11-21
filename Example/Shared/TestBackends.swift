//
//  TestBackends.swift
//  Example
//
//  The example backends that the example apps and testers call: the unified test backends
//  (oss-android-sdk's ci/test-backends), each under its own prefix, `<root><prefix>`. The root is
//  their Cloud Run deployment, or STRIPE_TEST_BACKENDS_URL in the app's environment, such as a local
//  copy's `http://127.0.0.1:4567/`. UI tests pass the variables on to the app in
//  `launchEnvironment`.
//

import Foundation

enum TestBackend: String {
    case playground
    case paymentSheet = "payment-sheet"
    case paymentSheetCustomDeferred = "payment-sheet-custom-deferred"
    case identityPlayground = "identity-playground"
    case connectExample = "connect-example"
    case cryptoOnramp = "crypto-onramp"
    case connectionsWebview = "connections-webview"
    case iosFinancialConnectionsPlayground = "ios-financial-connections-playground"
    case integrationTester = "integration-tester"
    case linkControllerPreviewDemo = "link-controller-preview-demo"
    case linkPayoutsDemo = "link-payouts-demo"
    case cardScanCIVExample = "card-scan-civ-example"

    /// Overrides `defaultURL`.
    static let urlEnvironmentKey = "STRIPE_TEST_BACKENDS_URL"
    static let defaultURL = "https://stp-mobile-test-backends-764603794666.us-central1.run.app/"

    /// The variables that a UI test puts in the app's `launchEnvironment` to pass on the test
    /// backends it was given.
    static var launchEnvironment: [String: String] {
        ProcessInfo.processInfo.environment.filter { $0.key == urlEnvironmentKey }
    }

    /// STRIPE_TEST_BACKENDS_URL or `defaultURL`, with a trailing slash.
    static func rootURL(environment: [String: String] = ProcessInfo.processInfo.environment) -> String {
        let root = environment[urlEnvironmentKey].flatMap { $0.isEmpty ? nil : $0 } ?? defaultURL
        return root.hasSuffix("/") ? root : root + "/"
    }

    /// The backend's URL, without a trailing slash.
    var baseURL: String {
        baseURL(environment: ProcessInfo.processInfo.environment)
    }

    func baseURL(environment: [String: String]) -> String {
        Self.rootURL(environment: environment) + rawValue
    }

    var url: URL {
        URL(string: baseURL)!
    }
}
