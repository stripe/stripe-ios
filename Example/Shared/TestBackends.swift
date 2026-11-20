//
//  TestBackends.swift
//  Example
//
//  The example backends that the example apps and testers call. Each is a hosted
//  stripedemos.com backend unless STRIPE_TEST_BACKENDS_URL, in the app's environment, names the
//  root of the unified test backends (oss-android-sdk's ci/test-backends); then each backend is
//  `<root><prefix>`. UI tests pass the variables on to the app in `launchEnvironment`.
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

    static let urlEnvironmentKey = "STRIPE_TEST_BACKENDS_URL"
    static let tokenEnvironmentKey = "STRIPE_TEST_BACKENDS_TOKEN"

    /// The variables that a UI test puts in the app's `launchEnvironment` to pass on the test
    /// backends it was given.
    static var launchEnvironment: [String: String] {
        ProcessInfo.processInfo.environment.filter { [urlEnvironmentKey, tokenEnvironmentKey].contains($0.key) }
    }

    /// The backend's URL, without a trailing slash.
    ///
    /// With STRIPE_TEST_BACKENDS_TOKEN set too, the URL carries the token as a `_t/<token>/`
    /// prefix, which the test backends accept in place of the X-Test-Backends-Token header, so
    /// that every request the apps make, web views included, has it.
    var baseURL: String {
        let environment = ProcessInfo.processInfo.environment
        guard var root = environment[Self.urlEnvironmentKey], !root.isEmpty else {
            return hostedURL
        }
        if !root.hasSuffix("/") {
            root += "/"
        }
        if let token = environment[Self.tokenEnvironmentKey], !token.isEmpty {
            root += "_t/\(token)/"
        }
        return root + rawValue
    }

    var url: URL {
        URL(string: baseURL)!
    }

    private var hostedURL: String {
        switch self {
        case .playground: return "https://stp-mobile-playground-backend-v7.stripedemos.com"
        case .paymentSheet: return "https://stripe-mobile-payment-sheet.stripedemos.com"
        case .paymentSheetCustomDeferred: return "https://stripe-mobile-payment-sheet-custom-deferred.stripedemos.com"
        case .identityPlayground: return "https://stripe-mobile-identity-verification-playground.stripedemos.com"
        case .connectExample: return "https://stripe-connect-mobile-example-v1.stripedemos.com"
        case .cryptoOnramp: return "https://crypto-onramp-example.stripedemos.com"
        case .connectionsWebview: return "https://connections-webview-example.stripedemos.com"
        case .iosFinancialConnectionsPlayground: return "https://ios-financial-connections-playground.stripedemos.com"
        case .integrationTester: return "https://stp-integration-tester-v3.stripedemos.com"
        case .linkControllerPreviewDemo: return "https://link-controller-preview-demo.stripedemos.com"
        case .linkPayoutsDemo: return "https://link-payouts-demo.stripedemos.com"
        case .cardScanCIVExample: return "https://stripe-card-scan-civ-example-app.stripedemos.com"
        }
    }
}
