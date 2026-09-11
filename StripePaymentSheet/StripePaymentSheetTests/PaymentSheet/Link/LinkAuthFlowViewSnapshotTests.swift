// Copyright © 2026 Stripe, Inc. All rights reserved.

import OHHTTPStubs
import OHHTTPStubsSwift
@testable @_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripeUICore
import XCTest

#if !os(visionOS)
@MainActor
final class LinkAuthFlowViewSnapshotTests: STPSnapshotTestCase {
    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testEmailOTPModal() {
        let flow = makeFlow(types: [.email])
        startAndWait(flow)
        snapshot(flow)
    }

    func testEmailOTPEmbedded() {
        let flow = makeFlow(types: [.email], mode: .embedded)
        startAndWait(flow)
        snapshot(flow)
    }

    func testSMSMoreOptionsModal() {
        let flow = makeFlow(types: [.sms, .email])
        startAndWait(flow)
        snapshot(flow)
    }

    func testPhoneMatchModal() {
        let flow = makeFlow(types: [.email], phoneMatch: true)
        startAndWait(flow)
        snapshot(flow)
    }

    func testPhoneMatchBackRestoresSMSWithoutAnotherSend() {
        var requests = 0
        let flow = makeFlow(types: [.sms, .email], phoneMatch: true, onStart: { requests += 1 })
        startAndWait(flow)
        flow.coordinator.sendToEmail()
        XCTAssertEqual(flow.coordinator.screen, .phoneMatch)
        XCTAssertTrue(flow.coordinator.canGoBack)
        XCTAssertEqual(flow.children.count, 1)
        snapshot(flow)
        flow.back()
        flow.viewDidAppear(false)
        XCTAssertEqual(flow.coordinator.screen, .otp)
        XCTAssertEqual(flow.children.count, 1)
        XCTAssertEqual(requests, 1)
    }

    func testPhoneMatchEmbeddedDark() {
        let flow = makeFlow(types: [.email], phoneMatch: true, mode: .embedded)
        flow.overrideUserInterfaceStyle = .dark
        startAndWait(flow)
        snapshot(flow)
    }

    func testPresentedModalFitsAboveKeyboardAndScrollsForAccessibilityText() throws {
        // Given the real modal presentation, including its presentation controller.
        let flow = makeFlow(types: [.sms, .email], phoneMatch: true)
        startAndWait(flow)
        let window = UIWindow(frame: UIScreen.main.bounds)
        let presenter = UIViewController()
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        defer {
            flow.close()
            presenter.dismiss(animated: false)
            window.isHidden = true
        }
        let presented = expectation(description: "Auth modal presented")
        presenter.present(flow, animated: false) { presented.fulfill() }
        wait(for: [presented], timeout: 5)
        let presentation = try XCTUnwrap(flow.presentationController as? LinkAuthFlowViewController.PresentationController)

        // When the keyboard leaves limited space and the user advances to phone match.
        let keyboardTop = window.bounds.height * 0.6
        let keyboardFrame = CGRect(x: 0, y: keyboardTop, width: window.bounds.width, height: window.bounds.height - keyboardTop)
        flow.coordinator.sendToEmail()
        flow.view.endEditing(true)
        let keyboardNotification = Notification(name: UIResponder.keyboardWillChangeFrameNotification, userInfo: [
            UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: keyboardFrame),
            UIResponder.keyboardAnimationDurationUserInfoKey: 0,
        ])
        presentation.keyboardFrameChanged(keyboardNotification)
        flow.view.layoutIfNeeded()

        // Then the modal remains inside the visible space.
        XCTAssertGreaterThan(flow.view.frame.width, 0)
        XCTAssertLessThanOrEqual(flow.view.frame.maxY, keyboardTop + 1)
        XCTAssertEqual(flow.coordinator.screen, .phoneMatch)

        if #available(iOS 17.0, *) {
            window.traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
            window.updateTraitsIfNeeded()
            flow.view.updateTraitsIfNeeded()
            flow.children.first?.view.updateTraitsIfNeeded()
            let traitsUpdated = expectation(description: "Accessibility traits propagated")
            DispatchQueue.main.async { traitsUpdated.fulfill() }
            wait(for: [traitsUpdated], timeout: 2)
            XCTAssertEqual(flow.children.first?.traitCollection.preferredContentSizeCategory, .accessibilityExtraExtraExtraLarge)
            presentation.keyboardFrameChanged(keyboardNotification)
            flow.view.setNeedsLayout()
            flow.view.layoutIfNeeded()
            presentation.updatePresentedViewFrame()
            flow.view.layoutIfNeeded()
            let scrollView = try XCTUnwrap(flow.view as? UIScrollView)
            XCTAssertLessThanOrEqual(flow.view.frame.maxY, keyboardTop + 1)
            XCTAssertGreaterThan(scrollView.contentSize.height, scrollView.bounds.height)
        }
    }

    func testPhoneMismatchInline() {
        let flow = makeFlow(types: [.email], phoneMatch: true)
        startAndWait(flow)
        stub(condition: isPath("/v1/consumers/sessions/start_verification")) { _ in
            HTTPStubsResponse(jsonObject: ["error": ["type": "invalid_request_error", "code": "phone_number_mismatch", "message": "The phone number doesn't match your account."]], statusCode: 400, headers: nil)
        }
        let failed = expectation(description: "Phone error displayed")
        let render = flow.coordinator.onUpdate
        flow.coordinator.onUpdate = { [weak flow] in
            render?()
            if flow?.coordinator.errorMessage != nil { failed.fulfill() }
        }
        flow.coordinator.submitPhoneNumber("+14155550123")
        wait(for: [failed], timeout: 5)
        flow.coordinator.onUpdate = render
        snapshot(flow)
    }

    private func startAndWait(_ flow: LinkAuthFlowViewController) {
        flow.loadViewIfNeeded()
        let ready = expectation(description: "Auth screen ready")
        let render = flow.coordinator.onUpdate
        var fulfilled = false
        flow.coordinator.onUpdate = { [weak flow] in
            guard let flow else { return }
            render?()
            if !flow.coordinator.isLoading, !fulfilled {
                fulfilled = true
                ready.fulfill()
            }
        }
        flow.coordinator.start()
        wait(for: [ready], timeout: 5)
        flow.coordinator.onUpdate = render
    }

    private func snapshot(_ flow: LinkAuthFlowViewController) {
        let height = flow.fittingHeight(width: 340)
        XCTAssertLessThan(height, 450, "Default-size auth content should fit in a compact dialog")
        flow.view.frame = CGRect(x: 0, y: 0, width: 340, height: height)
        let window = UIWindow(frame: flow.view.frame)
        window.rootViewController = flow
        window.isHidden = false
        flow.view.layoutIfNeeded()
        STPSnapshotVerifyView(flow.view)
        window.isHidden = true
    }

    private func makeFlow(types: [SupportedVerificationType], phoneMatch: Bool = false, mode: LinkVerificationView.Mode = .modal, onStart: @escaping () -> Void = {}) -> LinkAuthFlowViewController {
        let factors = types.map { ConsumerSession.VerificationFactor(type: $0 == .sms ? .sms : .email, providesFurtherVerification: true, temporarilyDisabled: false, id: $0.rawValue) }
        let session = ConsumerSession.make(clientSecret: "secret", emailAddress: "jane.diaz@example.com", redactedFormattedPhoneNumber: "(***) *** **23", unredactedPhoneNumber: nil, phoneNumberCountry: "US", verificationSessions: [], supportedPaymentDetailsTypes: [], mobileFallbackWebviewParams: nil, currentAuthenticationLevel: .notAuthenticated, minimumAuthenticationLevel: .oneFactorAuth, availableVerificationFactors: factors, redactedPhoneNumber: "+1********23")
        let account = PaymentSheetLinkAccount(email: session.emailAddress, session: session, publishableKey: "pk_test_consumer", displayablePaymentDetails: nil, apiClient: STPAPIClient(publishableKey: "pk_test_auth"), useMobileEndpoints: true, canSyncAttestationState: false)
        account.authLookupSettings = .init(emailOtpRequiresAdditionalInfo: phoneMatch)
        stub(condition: isPath("/v1/consumers/sessions/start_verification")) { request in
            onStart()
            let type = RequestBodyTestHelpers.formEncodedBodyParams(from: request)["type"] ?? "SMS"
            return HTTPStubsResponse(jsonObject: ["consumer_session": [
                "client_secret": "secret", "email_address": "jane.diaz@example.com", "redacted_formatted_phone_number": "(***) *** **23", "phone_number_country": "US", "redacted_phone_number": "+1********23",
                "current_authentication_level": "NOT_AUTHENTICATED", "minimum_authentication_level": "1FA",
                "verification_sessions": [["type": type, "state": "STARTED"]],
                "available_verification_factors": types.map { ["type": $0.rawValue, "provides_further_verification": true, "temporarily_disabled": false, "id": $0.rawValue] },
            ],
            ], statusCode: 200, headers: nil)
        }
        return LinkAuthFlowViewController(mode: mode, linkAccount: account, brand: .link)
    }
}
#endif
