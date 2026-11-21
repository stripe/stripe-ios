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
    /// Overrides `defaultBypass`.
    static let bypassEnvironmentKey = "STRIPE_TEST_BACKENDS_BYPASS"
    /// The unified test backends' Vercel deployment answers only requests with its Protection
    /// Bypass for Automation secret, which is deliberately public.
    static let defaultBypass = "PublicAvailableiOSAndroidBackend"
    static let bypassHeader = "x-vercel-protection-bypass"

    /// The variables that a UI test puts in the app's `launchEnvironment` to pass on the test
    /// backends it was given.
    static var launchEnvironment: [String: String] {
        ProcessInfo.processInfo.environment.filter { [urlEnvironmentKey, bypassEnvironmentKey].contains($0.key) }
    }

    /// STRIPE_TEST_BACKENDS_URL or `defaultURL`, with a trailing slash.
    static func rootURL(environment: [String: String] = ProcessInfo.processInfo.environment) -> String {
        let root = environment[urlEnvironmentKey].flatMap { $0.isEmpty ? nil : $0 } ?? defaultURL
        return root.hasSuffix("/") ? root : root + "/"
    }

    /// The bypass secret that requests to the test backends carry: STRIPE_TEST_BACKENDS_BYPASS,
    /// or else `defaultBypass` unless the root is a local copy of the backends, which isn't
    /// behind Vercel.
    static func bypass(environment: [String: String] = ProcessInfo.processInfo.environment) -> String? {
        if let bypass = environment[bypassEnvironmentKey], !bypass.isEmpty {
            return bypass
        }
        let host = URL(string: rootURL(environment: environment))?.host?.lowercased()
        return ["127.0.0.1", "localhost", "::1"].contains(host) ? nil : defaultBypass
    }

    /// Adds the bypass to a URL for a web view's first page, as query parameters that make Vercel
    /// set a cookie for the page's other requests: web views don't load through
    /// `TestBackendsURLProtocol`.
    static func addingBypass(to url: URL, environment: [String: String] = ProcessInfo.processInfo.environment) -> URL {
        guard let bypass = bypass(environment: environment),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return url
        }
        components.queryItems = (components.queryItems ?? []) + [
            URLQueryItem(name: bypassHeader, value: bypass),
            URLQueryItem(name: "x-vercel-set-bypass-cookie", value: "true"),
        ]
        return components.url ?? url
    }

    /// The backend's URL, without a trailing slash.
    var baseURL: String {
        baseURL(environment: ProcessInfo.processInfo.environment)
    }

    func baseURL(environment: [String: String]) -> String {
        TestBackendsURLProtocol.register()
        return Self.rootURL(environment: environment) + rawValue
    }

    var url: URL {
        URL(string: baseURL)!
    }
}

/// Adds the bypass header to every `URLSession.shared` request for the test backends, the way
/// stripe-android's interceptor does: the apps make their requests through `URLSession.shared`,
/// which can't be given headers of its own.
final class TestBackendsURLProtocol: URLProtocol {
    private static let handledRequestKey = "TestBackendsURLProtocolHandledRequest"
    private static let registration: Void = {
        URLProtocol.registerClass(TestBackendsURLProtocol.self)
    }()

    private var dataTask: URLSessionDataTask?

    static func register() {
        _ = registration
    }

    override static func canInit(with request: URLRequest) -> Bool {
        guard TestBackend.bypass() != nil,
              request.value(forHTTPHeaderField: TestBackend.bypassHeader) == nil,
              URLProtocol.property(forKey: handledRequestKey, in: request) == nil,
              let url = request.url,
              let root = URL(string: TestBackend.rootURL())
        else {
            return false
        }
        return url.host?.lowercased() == root.host?.lowercased() && url.port == root.port
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let forwardedRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        forwardedRequest.setValue(TestBackend.bypass(), forHTTPHeaderField: TestBackend.bypassHeader)
        URLProtocol.setProperty(true, forKey: Self.handledRequestKey, in: forwardedRequest)

        // A session of its own: URLSession.shared would hand the request back to this protocol.
        let session = URLSession(configuration: .default)
        dataTask = session.dataTask(with: forwardedRequest as URLRequest) { [weak self] data, response, error in
            defer { session.finishTasksAndInvalidate() }
            guard let self else { return }
            if let response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data {
                client?.urlProtocol(self, didLoad: data)
            }
            if let error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }
        }
        dataTask?.resume()
    }

    override func stopLoading() {
        dataTask?.cancel()
    }
}
