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

    @MainActor
    func testPresent_whileAlreadyPresentingThrowsError() async {
        do {
            let manager = AuthenticatedWebViewManager { url, scheme, handler in
                XCTFail("Manager should not be instantiated")
                return MockWebAuthenticationSession(url: url, callbackURLScheme: scheme, completionHandler: handler)
            }
            let alreadyPresentingSession = MockWebAuthenticationSession(url: URL("https://already_presenting")!, callbackURLScheme: nil, completionHandler: { _, _ in })
            manager.authSession = alreadyPresentingSession

            _ = try await manager.present(with: URL("https://new_present")!, in: UIWindow())

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

            _ = try await manager.present(with: URL("https://stripe.com")!, in: nil)

            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? AuthenticatedWebViewError, AuthenticatedWebViewError.noWindow)
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

            _ = try await manager.present(with: URL("https://stripe.com")!, in: UIWindow())

            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? AuthenticatedWebViewError, AuthenticatedWebViewError.cannotStartSession)
        }
        XCTAssertEqual(mockAuthSession?.didStart, false)
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
            mockAuthSession.overrideCompletionResult = .success(URL("stripe-connect://success")!)
            return mockAuthSession
        }

        let result = try await manager.present(with: URL("https://stripe.com")!, in: UIWindow())

        XCTAssertEqual(result, URL("stripe-connect://success")!)
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

        let result = try await manager.present(with: URL("https://stripe.com")!, in: UIWindow())

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
            _ = try await manager.present(with: URL("https://stripe.com")!, in: UIWindow())
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual((error as NSError).domain, "custom_error")
            XCTAssertEqual((error as NSError).code, 111)
        }
    }
}

private class MockWebAuthenticationSession: ASWebAuthenticationSession {
    var overrideCanStart: Bool = true

    var didStart = false

    var overrideCompletionResult: Result<URL, Error>?

    private let completionHandler: CompletionHandler

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
            do {
                completionHandler(try overrideCompletionResult.get(), nil)
            } catch {
                completionHandler(nil, error)
            }
        }

        return overrideCanStart
    }
}
