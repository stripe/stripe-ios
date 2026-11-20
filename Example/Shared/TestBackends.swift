//
//  TestBackends.swift
//  Example
//
//  The example backends that the example apps and testers call: the unified test backends
//  (oss-android-sdk's ci/test-backends), each under its own prefix, `<root><prefix>`. The root is
//  their Vercel deployment, or STRIPE_TEST_BACKENDS_URL in the app's environment, such as a local
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
    static let defaultURL = "https://stripe-mobile-example-ci-backends.vercelapp.stripe.dev/"
    static let tokenEnvironmentKey = "STRIPE_TEST_BACKENDS_TOKEN"
    /// Overrides `defaultBypass`.
    static let bypassEnvironmentKey = "STRIPE_TEST_BACKENDS_BYPASS"
    /// The unified test backends' Vercel deployment answers only requests with its Protection
    /// Bypass for Automation secret, which is deliberately public.
    static let defaultBypass = "PublicAvailableiOSAndroidBackend"

    /// The variables that a UI test puts in the app's `launchEnvironment` to pass on the test
    /// backends it was given.
    static var launchEnvironment: [String: String] {
        ProcessInfo.processInfo.environment.filter {
            [urlEnvironmentKey, tokenEnvironmentKey, bypassEnvironmentKey].contains($0.key)
        }
    }

    /// The bypass secret that requests to the test backends carry: STRIPE_TEST_BACKENDS_BYPASS,
    /// or else `defaultBypass` unless STRIPE_TEST_BACKENDS_URL is a local copy of the backends,
    /// which isn't behind Vercel.
    static var bypass: String? {
        if let bypass = ProcessInfo.processInfo.environment[bypassEnvironmentKey], !bypass.isEmpty {
            return bypass
        }
        let host = URL(string: rootURL)?.host?.lowercased()
        return ["127.0.0.1", "localhost", "::1"].contains(host) ? nil : defaultBypass
    }

    /// Adds the bypass to a URL for a web view's first page, as query parameters that make Vercel
    /// set a cookie for the page's other requests.
    static func addingBypass(to url: URL) -> URL {
        guard let bypass, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        components.queryItems = (components.queryItems ?? []) + [
            URLQueryItem(name: "x-vercel-protection-bypass", value: bypass),
            URLQueryItem(name: "x-vercel-set-bypass-cookie", value: "true"),
        ]
        return components.url ?? url
    }

    /// The apps make their requests through `URLSession.shared`, which can't add headers, so the
    /// first time they ask for a backend's URL this requests the test backends' root once with the
    /// bypass. Vercel's bypass cookie then goes in `HTTPCookieStorage.shared`, which sends it with
    /// every later request. Web views have their own cookies: load the first page with
    /// `addingBypass(to:)`.
    private static let setBypassCookie: Void = {
        guard let bypass, let root = URL(string: rootURL) else {
            return
        }
        var request = URLRequest(url: root, timeoutInterval: 15)
        request.setValue(bypass, forHTTPHeaderField: "x-vercel-protection-bypass")
        request.setValue("true", forHTTPHeaderField: "x-vercel-set-bypass-cookie")
        let done = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error {
                print("Couldn't set the test backends' Vercel bypass cookie: \(error)")
            }
            done.signal()
        }.resume()
        _ = done.wait(timeout: .now() + 15)
    }()

    /// STRIPE_TEST_BACKENDS_URL or `defaultURL`, with a trailing slash, plus `_t/<token>/` with
    /// STRIPE_TEST_BACKENDS_TOKEN set.
    private static var rootURL: String {
        let environment = ProcessInfo.processInfo.environment
        var root = environment[urlEnvironmentKey].flatMap { $0.isEmpty ? nil : $0 } ?? defaultURL
        if !root.hasSuffix("/") {
            root += "/"
        }
        if let token = environment[tokenEnvironmentKey], !token.isEmpty {
            root += "_t/\(token)/"
        }
        return root
    }

    /// The backend's URL, without a trailing slash.
    ///
    /// With STRIPE_TEST_BACKENDS_TOKEN set too, the URL carries the token as a `_t/<token>/`
    /// prefix, which the test backends accept in place of the X-Test-Backends-Token header, so
    /// that every request the apps make, web views included, has it.
    var baseURL: String {
        _ = Self.setBypassCookie
        return Self.rootURL + rawValue
    }

    var url: URL {
        URL(string: baseURL)!
    }
}
