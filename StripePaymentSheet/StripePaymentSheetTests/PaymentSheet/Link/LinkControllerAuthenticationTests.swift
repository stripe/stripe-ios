//
//  LinkControllerAuthenticationTests.swift
//  StripePaymentSheetTests
//

import OHHTTPStubs
import OHHTTPStubsSwift
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePaymentSheet
import XCTest

#if !os(visionOS)
@MainActor
final class LinkControllerAuthenticationTests: APIStubbedTestCase {
    private let content = LinkController.AuthenticationContent(
        title: "Continue with Link",
        subtitle: "Sign in",
        consentAction: .clicked_button_mobile_v1
    )
    private var window: UIWindow?

    override func setUp() {
        super.setUp()
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = true
        // Link's screens start verification and attestation on their own; only the requests a test stubs succeed.
        stub { _ in true } response: { _ in
            HTTPStubsResponse(data: Data(), statusCode: 400, headers: nil)
        }
        StubbedBackend.stubSessions(paymentMethods: "\"card\", \"link\"")
        addTeardownBlock { @MainActor [weak self] in
            self?.window?.rootViewController?.dismiss(animated: false)
            self?.window?.isHidden = true
            self?.window = nil
            LinkAccountContext.shared.account = nil
            PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = nil
        }
    }

    func testVerifiedAccountForTheSameEmailAuthenticatesWithoutPresenting() async throws {
        // Given Link already has a verified session for the user
        let controller = try await makeController()
        await share(verifiedAccount())
        let host = TestViewController(onPresentChild: { _ in XCTFail("A verified session must not present Link") })

        // When Identity asks for the same email, in any case
        var result: Result<LinkController.AuthenticationResult, Error>?
        controller.presentForAuthentication(email: "USER@example.com", content: content, from: host) { result = $0 }

        // Then it's authenticated right away
        guard case .success(.authenticated) = result else {
            return XCTFail("Expected an immediate authentication, got \(String(describing: result))")
        }
    }

    func testWithoutAnEmailLinksSheetAsksForOne() async throws {
        // Given another account's verified session is shared
        let controller = try await makeController()
        await share(verifiedAccount())
        let presented = expectation(description: "Link's sheet is presented")
        let host = makeHost { if $0 is PayWithLinkViewController { presented.fulfill() } }

        // When Identity has no email to sign in with
        var result: Result<LinkController.AuthenticationResult, Error>?
        controller.presentForAuthentication(email: nil, content: content, from: host) { result = $0 }

        // Then that session isn't reused and Link's sheet asks for an email
        XCTAssertNil(LinkAccountContext.shared.account)
        await fulfillment(of: [presented], timeout: 5)
        XCTAssertNil(result)
    }

    func testExistingAccountIsVerifiedInLinksDialog() async throws {
        // Given the email belongs to an account that needs a code
        let controller = try await makeController()
        StubbedBackend.stubLookup()
        let presented = expectation(description: "Verification dialog is presented")
        let host = makeHost { if $0 is LinkVerificationViewController { presented.fulfill() } }

        // When Identity signs in with that email
        controller.presentForAuthentication(email: "foo@bar.com", content: content, from: host) { _ in }

        // Then Link's verification dialog asks for the code
        await fulfillment(of: [presented], timeout: 5)
    }

    func testSwitchingAccountContinuesInLinksSheet() async throws {
        // Given Link's verification dialog is asking for a code
        let controller = try await makeController()
        StubbedBackend.stubLookup()
        var verificationViewController: LinkVerificationViewController?
        let verificationPresented = expectation(description: "Verification dialog is presented")
        let sheetPresented = expectation(description: "Link's sheet is presented")
        let host = makeHost { viewController in
            if let viewController = viewController as? LinkVerificationViewController {
                verificationViewController = viewController
                verificationPresented.fulfill()
            } else if viewController is PayWithLinkViewController {
                sheetPresented.fulfill()
            }
        }
        var result: Result<LinkController.AuthenticationResult, Error>?
        controller.presentForAuthentication(email: "foo@bar.com", content: content, from: host) { result = $0 }
        await fulfillment(of: [verificationPresented], timeout: 5)
        let dialog = try XCTUnwrap(verificationViewController)
        await waitUntil { !dialog.isBeingPresented }

        // When the user says it isn't their account
        dialog.delegate?.verificationController(dialog, didFinishWithResult: .switchAccount)

        // Then Link's sheet asks for another email
        await fulfillment(of: [sheetPresented], timeout: 5)
        XCTAssertNil(LinkAccountContext.shared.account)
        XCTAssertNil(result)
    }
}

private extension LinkControllerAuthenticationTests {
    func makeController() async throws -> LinkController {
        let apiClient = stubbedAPIClient()
        // A test-mode key keeps Link from leaving for the web when the simulator can't attest.
        apiClient.publishableKey = "pk_test_123"
        return try await LinkController.create(apiClient: apiClient, mode: .setup, requestSurface: .cryptoOnramp)
    }

    func verifiedAccount() -> PaymentSheetLinkAccount {
        LinkStubs.account(
            session: .make(
                clientSecret: "client_secret",
                emailAddress: "user@example.com",
                redactedFormattedPhoneNumber: "(***) *** **55",
                unredactedPhoneNumber: nil,
                phoneNumberCountry: "US",
                verificationSessions: [],
                supportedPaymentDetailsTypes: [],
                mobileFallbackWebviewParams: nil,
                currentAuthenticationLevel: .twoFactorAuth,
                minimumAuthenticationLevel: .oneFactorAuth
            )
        )
    }

    /// Shares `account` with every `LinkController`, which picks it up on the main queue.
    func share(_ account: PaymentSheetLinkAccount) async {
        LinkAccountContext.shared.account = account
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }

    func makeHost(onPresentChild: @escaping (UIViewController) -> Void) -> UIViewController {
        let host = TestViewController(onPresentChild: onPresentChild)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        self.window = window
        return host
    }

    func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<100 where !condition() {
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }
}
#endif
