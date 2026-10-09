//
//  AuthenticatedWebViewManagerTests.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/15/24.
//

import AuthenticationServices
@testable import StripeConnect
import XCTest

class AuthenticatedWebViewManagerTests: XCTestCase {

    /// Hold onto reference to UIWindow
    private let mockWindow = UIWindow()

    /// A UIView embedded in a window
    private let mockViewInWindow = UIView()

    override func setUp() {
        super.setUp()
        mockWindow.addSubview(mockViewInWindow)
    }

    @MainActor
    func testPresent_whileAlreadyPresentingThrowsError() async {
        do {
            let manager = AuthenticatedWebViewManager { url, scheme, handler in
                XCTFail("Manager should not be instantiated")
                return MockWebAuthenticationSession(url: url, callbackURLScheme: scheme, completionHandler: handler)
            }
            let alreadyPresentingSession = MockWebAuthenticationSession(url: URL(string: "https://already_presenting")!, callbackURLScheme: nil, completionHandler: { _, _ in })
            manager.authSession = alreadyPresentingSession

            _ = try await manager.present(with: URL(string: "https://new_present")!, from: mockViewInWindow)

            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? AuthenticatedWebViewError, AuthenticatedWebViewError.alreadyPresenting)
        }
    }

    func testPresent_withoutWindowThrowsError() async {
        do {
            let manager = AuthenticatedWebViewManager { url, scheme, handler in
                XCTFail("Manager should not be instantiated")
                return MockWebAuthenticationSession(url: url, callbackURLScheme: scheme, completionHandler: handler)
            }

            _ = try await manager.present(with: URL(string: "https://stripe.com")!, from: UIView())

            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? AuthenticatedWebViewError, AuthenticatedWebViewError.notInViewHierarchy)
        }
    }

    func testPresent_cannotStartThrowsError() async {
        var mockAuthSession: MockWebAuthenticationSession?
        do {
            let manager = AuthenticatedWebViewManager { url, scheme, handler in
                mockAuthSession = MockWebAuthenticationSession(url: url, callbackURLScheme: scheme, completionHandler: handler)

                // Mock that auth session can't start
                mockAuthSession?.overrideCanStart = false
                return mockAuthSession!
            }

            _ = try await manager.present(with: URL(string: "https://stripe.com")!, from: mockViewInWindow)

            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? AuthenticatedWebViewError, AuthenticatedWebViewError.cannotStartSession)
        }
        XCTAssertEqual(mockAuthSession?.didStart, false)
    }

    func testPresent_rejectsCustomSchemeBeforeCreatingSession() async throws {
        try await assertInvalidURL("myapp://authentication")
    }

    func testPresent_rejectsSDKReturnSchemeBeforeCreatingSession() async throws {
        try await assertInvalidURL("\(StripeConnectConstants.authenticatedWebViewReturnUrlScheme)://return")
    }

    func testPresent_rejectsJavaScriptURLBeforeCreatingSession() async throws {
        try await assertInvalidURL("javascript:alert(1)")
    }

    func testPresent_rejectsDataURLBeforeCreatingSession() async throws {
        try await assertInvalidURL("data:text/html,authentication")
    }

    func testPresent_rejectsFileURLBeforeCreatingSession() async throws {
        try await assertInvalidURL("file:///authentication")
    }

    func testPresent_rejectsAboutURLBeforeCreatingSession() async throws {
        try await assertInvalidURL("about:blank")
    }

    func testPresent_rejectsHostlessHTTPSURLBeforeCreatingSession() async throws {
        let url = try XCTUnwrap(URL(string: "https:///authentication"))
        XCTAssertEqual(url.scheme?.lowercased(), "https")
        XCTAssertTrue(url.host?.isEmpty ?? true)
        try await assertInvalidURL(url)
    }

    func testPresent_rejectsRelativeURLBeforeCreatingSession() async throws {
        try await assertInvalidURL("/authentication")
    }

    @MainActor
    func testPresent_acceptsUppercaseHTTPSScheme() async throws {
        let manager = AuthenticatedWebViewManager { url, scheme, handler in
            let session = MockWebAuthenticationSession(url: url, callbackURLScheme: scheme, completionHandler: handler)
            session.overrideCompletionResult = .success(URL(string: "stripe-connect://success")!)
            return session
        }

        let destination = try XCTUnwrap(URL(string: "HTTPS://example.test/authentication"))
        XCTAssertEqual(destination.scheme, "HTTPS")

        let result = try await manager.present(with: destination, from: mockViewInWindow)

        XCTAssertEqual(result, URL(string: "stripe-connect://success"))
    }

    @MainActor
    func testPresent_validatesDestinationBeforeAlreadyPresentingState() async throws {
        let sessionCreated = expectation(description: "Initial HTTPS session is created")
        var sessions: [MockWebAuthenticationSession] = []
        let manager = AuthenticatedWebViewManager { url, scheme, handler in
            let session = MockWebAuthenticationSession(url: url, callbackURLScheme: scheme, completionHandler: handler)
            if !sessions.isEmpty {
                session.overrideCompletionResult = .success(URL(string: "stripe-connect://unexpected-return")!)
            }
            sessions.append(session)
            sessionCreated.fulfill()
            return session
        }

        let firstRequest = Task { @MainActor in
            try await manager.present(with: URL(string: "https://example.test/first")!, from: self.mockViewInWindow)
        }
        await fulfillment(of: [sessionCreated], timeout: TestHelpers.defaultTimeout)
        let firstSession = try XCTUnwrap(sessions.first)
        XCTAssertTrue(manager.authSession === firstSession)

        do {
            _ = try await manager.present(with: try XCTUnwrap(URL(string: "file:///authentication")), from: mockViewInWindow)
            XCTFail("Expected invalid URL error")
        } catch {
            XCTAssertEqual(error as? AuthenticatedWebViewError, .invalidURL)
        }

        XCTAssertTrue(manager.authSession === firstSession)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertFalse(firstSession.didCancel)
        XCTAssertEqual(firstSession.cancelCount, 0)
        XCTAssertEqual(firstSession.completionCount, 0)
        firstSession.complete(with: .success(URL(string: "stripe-connect://success")!))
        let firstResult = try await firstRequest.value
        XCTAssertEqual(firstResult, URL(string: "stripe-connect://success"))
        XCTAssertEqual(firstSession.completionCount, 1)
    }

    @MainActor
    func testPresent_validatesDestinationBeforeWindowLookup() async {
        let manager = AuthenticatedWebViewManager { url, scheme, handler in
            XCTFail("Manager should not create a session for an invalid destination")
            let session = MockWebAuthenticationSession(url: url, callbackURLScheme: scheme, completionHandler: handler)
            session.overrideCompletionResult = .success(URL(string: "stripe-connect://unexpected-return")!)
            return session
        }

        do {
            _ = try await manager.present(with: try XCTUnwrap(URL(string: "file:///authentication")), from: UIView())
            XCTFail("Expected invalid URL error")
        } catch {
            XCTAssertEqual(error as? AuthenticatedWebViewError, .invalidURL)
        }
    }

    @MainActor
    func testPresent_startsSession_success() async throws {
        let manager = AuthenticatedWebViewManager { url, scheme, handler in
            let mockAuthSession = MockWebAuthenticationSession(
                url: url,
                callbackURLScheme: scheme,
                completionHandler: handler
            )
            // Mock that completion handler completes as soon as the session is started with URL
            mockAuthSession.overrideCompletionResult = .success(URL(string: "stripe-connect://success")!)
            return mockAuthSession
        }

        let result = try await manager.present(with: URL(string: "https://stripe.com")!, from: mockViewInWindow)

        XCTAssertEqual(result?.absoluteString, "stripe-connect://success")
    }

    @MainActor
    func testPresent_startsSession_userCanceled() async throws {
        let manager = AuthenticatedWebViewManager { url, scheme, handler in
            let mockAuthSession = MockWebAuthenticationSession(
                url: url,
                callbackURLScheme: scheme,
                completionHandler: handler
            )
            // Mock that completion handler completes as soon as the session is started with canceledLogin error
            mockAuthSession.overrideCompletionResult = .failure(
                ASWebAuthenticationSessionError(
                    _nsError: NSError(domain: ASWebAuthenticationSessionError.errorDomain, code: ASWebAuthenticationSessionError.canceledLogin.rawValue)
                )
            )
            return mockAuthSession
        }

        let result = try await manager.present(with: URL(string: "https://stripe.com")!, from: mockViewInWindow)

        XCTAssertEqual(result, nil)
    }

    @MainActor
    func testPresent_startsSession_error() async {
        let manager = AuthenticatedWebViewManager { url, scheme, handler in
            let mockAuthSession = MockWebAuthenticationSession(
                url: url,
                callbackURLScheme: scheme,
                completionHandler: handler
            )
            // Mock that completion handler completes as soon as the session is started with error
            mockAuthSession.overrideCompletionResult = .failure(
                NSError(domain: "custom_error", code: 111)
            )
            return mockAuthSession
        }

        do {
            _ = try await manager.present(with: URL(string: "https://stripe.com")!, from: mockViewInWindow)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual((error as NSError).domain, "custom_error")
            XCTAssertEqual((error as NSError).code, 111)
        }
    }

    @MainActor
    private func assertInvalidURL(_ string: String) async throws {
        try await assertInvalidURL(try XCTUnwrap(URL(string: string)))
    }

    @MainActor
    private func assertInvalidURL(_ url: URL) async throws {
        let manager = AuthenticatedWebViewManager { url, scheme, handler in
            XCTFail("Manager should not create a session for an invalid destination")
            let session = MockWebAuthenticationSession(url: url, callbackURLScheme: scheme, completionHandler: handler)
            session.overrideCompletionResult = .success(URL(string: "stripe-connect://unexpected-return")!)
            return session
        }

        do {
            _ = try await manager.present(with: url, from: mockViewInWindow)
            XCTFail("Expected invalid URL error")
        } catch {
            XCTAssertEqual(error as? AuthenticatedWebViewError, .invalidURL)
        }
    }
}

private class MockWebAuthenticationSession: ASWebAuthenticationSession {
    var overrideCanStart: Bool = true

    var didStart = false

    var overrideCompletionResult: Result<URL, Error>?

    private let completionHandler: CompletionHandler
    private(set) var completionCount = 0
    private(set) var cancelCount = 0
    var didCancel: Bool { cancelCount > 0 }

    override init(url: URL, callbackURLScheme: String?, completionHandler: @escaping CompletionHandler) {
        self.completionHandler = completionHandler
        super.init(url: url, callbackURLScheme: callbackURLScheme, completionHandler: completionHandler)
    }

    override var canStart: Bool {
        overrideCanStart
    }

    override func start() -> Bool {
        didStart = true

        if let overrideCompletionResult {
            complete(with: overrideCompletionResult)
        }

        return overrideCanStart
    }

    override func cancel() {
        cancelCount += 1
    }

    func complete(with result: Result<URL, Error>) {
        completionCount += 1
        do {
            completionHandler(try result.get(), nil)
        } catch {
            completionHandler(nil, error)
        }
    }
}
