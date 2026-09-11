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

    func testOTPActionShowsLoadingFromTheFirstFrameUntilCodeIsSent() throws {
        for types: [SupportedVerificationType] in [[.sms, .email], [.email]] {
            // Given SMS with an email alternative, or email-only OTP.
            let flow = makeFlow(types: types)

            // When the screen is prepared before appearance and before requesting the code.
            flow.loadViewIfNeeded()
            let otp = try XCTUnwrap(flow.children.first as? LinkVerificationViewController)

            // Then the first frame already shows the spinner, with no active menu overlay.
            XCTAssertTrue(otp.verificationView.actionsButton.isLoading)
            XCTAssertFalse(otp.verificationView.actionsButton.isEnabled)
            XCTAssertTrue(otp.verificationView.actionsButton.isAccessibilityElement)

            // When the request succeeds, the action replaces the spinner.
            startAndWait(flow)
            XCTAssertFalse(otp.verificationView.actionsButton.isLoading)
            XCTAssertTrue(otp.verificationView.actionsButton.isEnabled)
            flow.close()
        }
    }

    func testPhoneMatchModal() {
        let flow = makeFlow(types: [.email], phoneMatch: true)
        startAndWait(flow)
        snapshot(flow)
    }

    func testEmailPhoneMatchIsTheFirstScreenBeforeAppearance() {
        for mode in [LinkVerificationView.Mode.modal, .embedded] {
            // Given email is the only native factor and lookup requires the account phone number.
            var requests = 0
            let flow = makeFlow(types: [.email], phoneMatch: true, mode: mode, onStart: { requests += 1 })

            // When UIKit loads the view, before starting authentication in viewDidAppear.
            flow.loadViewIfNeeded()

            // Then phone match is already visible; there is no placeholder SMS OTP screen.
            XCTAssertEqual(flow.coordinator.screen, .phoneMatch)
            XCTAssertEqual(flow.children.count, 1)
            XCTAssertTrue(flow.children.first is LinkPhoneMatchViewController)
            XCTAssertEqual(requests, 0)

            // When the modal appears, it still waits for phone submission without changing screens.
            let firstScreen = flow.children.first
            flow.viewDidAppear(false)
            XCTAssertTrue(flow.children.first === firstScreen)
            XCTAssertEqual(flow.coordinator.screen, .phoneMatch)
            XCTAssertEqual(requests, 0)
            flow.close()
        }
    }

    func testEmailOTPRecipientIsPreparedBeforeAppearanceWithoutSendingCode() {
        // Given email OTP does not require phone match.
        var requests = 0
        let flow = makeFlow(types: [.email], onStart: { requests += 1 })

        // When loading the view before presentation.
        flow.loadViewIfNeeded()

        // Then it shows the email recipient immediately but hasn't requested an OTP.
        XCTAssertEqual(flow.coordinator.screen, .otp)
        XCTAssertEqual(flow.coordinator.challenge?.type, .email)
        XCTAssertEqual(flow.coordinator.recipient, "jane.diaz@example.com")
        XCTAssertTrue(flow.children.first is LinkVerificationViewController)
        XCTAssertEqual(requests, 0)
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

    func testHeaderButtonsMatchWithPlainAppearance() throws {
        try verifyHeaderButtons(liquidGlass: false)
    }

    func testHeaderButtonsMatchWithLiquidGlassAppearance() throws {
        guard #available(iOS 26, *) else { throw XCTSkip("Liquid Glass requires iOS 26") }
        try verifyHeaderButtons(liquidGlass: true)
    }

    func testRenderingBeforePresentationDoesNotForceZeroWidthLayout() throws {
        // Given a loaded modal whose presentation controller has not received a container yet.
        let flow = makeFlow(types: [.sms, .email])
        let presentation = try XCTUnwrap(flow.presentationController as? LinkAuthFlowViewController.PresentationController)
        flow.loadViewIfNeeded()
        XCTAssertNil(presentation.containerView)
        XCTAssertEqual(flow.view.bounds.width, 0)
        let probe = LayoutProbeView()
        flow.view.addSubview(probe)
        probe.setNeedsLayout()

        // When the auth state renders before UIKit assigns the modal's frame.
        flow.coordinator.onUpdate?()

        // Then layout is deferred instead of resolving required margins at zero width.
        XCTAssertEqual(probe.layoutCount, 0)
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

    func testDismissalPreservesAnimationFrameAndCancellationRestoresKeyboardLayout() throws {
        // Given a presented OTP modal above the keyboard.
        let flow = makeFlow(types: [.sms, .email])
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
        flow.view.endEditing(true)
        let presentation = try XCTUnwrap(flow.presentationController as? LinkAuthFlowViewController.PresentationController)
        let keyboardFrame = CGRect(x: 0, y: window.bounds.height * 0.6, width: window.bounds.width, height: window.bounds.height * 0.4)
        let keyboardShown = Notification(name: UIResponder.keyboardWillChangeFrameNotification, userInfo: [
            UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: keyboardFrame),
            UIResponder.keyboardAnimationDurationUserInfoKey: 0,
        ])
        let keyboardHidden = Notification(name: UIResponder.keyboardWillHideNotification, userInfo: [
            UIResponder.keyboardAnimationDurationUserInfoKey: 0,
        ])
        presentation.keyboardFrameChanged(keyboardShown)
        let frameAboveKeyboard = flow.view.frame

        // When dismissal starts and UIKit moves the modal as part of its animation.
        presentation.dismissalTransitionWillBegin()
        let animationFrame = frameAboveKeyboard.offsetBy(dx: 0, dy: 80)
        flow.view.frame = animationFrame

        // Then keyboard and layout callbacks must not overwrite the animated frame.
        presentation.keyboardWillHide(keyboardHidden)
        XCTAssertEqual(flow.view.frame, animationFrame)
        presentation.keyboardFrameChanged(keyboardShown)
        XCTAssertEqual(flow.view.frame, animationFrame)
        flow.viewDidLayoutSubviews()
        presentation.containerViewWillLayoutSubviews()
        presentation.updatePresentedViewFrame()
        XCTAssertEqual(flow.view.frame, animationFrame)
        XCTAssertEqual(presentation.frameOfPresentedViewInContainerView, frameAboveKeyboard)

        // When dismissal is canceled, normal positioning and keyboard avoidance resume.
        presentation.dismissalTransitionDidEnd(false)
        XCTAssertEqual(flow.view.frame, frameAboveKeyboard)
        presentation.keyboardWillHide(keyboardHidden)
        XCTAssertGreaterThan(flow.view.frame.midY, frameAboveKeyboard.midY)
        presentation.keyboardFrameChanged(keyboardShown)
        XCTAssertEqual(flow.view.frame, frameAboveKeyboard)
    }

    private func verifyHeaderButtons(liquidGlass: Bool) throws {
        let originalAppearance = LinkUI.appearance
        let originalGlass = LinkUI.useLiquidGlass
        let originalGlassNavigation = LinkUI.useLiquidGlassNavigationBar
        defer {
            LinkUI.appearance = originalAppearance
            LinkUI.useLiquidGlass = originalGlass
            LinkUI.useLiquidGlassNavigationBar = originalGlassNavigation
        }
        LinkUI.useLiquidGlass = false
        LinkUI.useLiquidGlassNavigationBar = false
        LinkUI.appearance = .default
        if liquidGlass, #available(iOS 26, *) {
            var configuration = PaymentSheet.Configuration()
            configuration.appearance.applyLiquidGlass()
            configuration.appearance.navigationBarStyle = .glass
            LinkUI.applyLiquidGlassIfPossible(configuration: configuration)
        }

        // Given a modal with a Back button after switching from SMS to phone match.
        let flow = makeFlow(types: [.sms, .email], phoneMatch: true)
        startAndWait(flow)
        flow.coordinator.sendToEmail()

        // When laying out the complete modal, including the header's contribution to its height.
        snapshot(flow)
        let header = try XCTUnwrap(findHeader(in: flow.view))
        let expectedSize: CGFloat = liquidGlass ? 48 : 32

        // Then both controls share the navigation-button component and have matching square bounds.
        XCTAssertTrue(header.backButton is SheetNavigationButton)
        XCTAssertTrue(header.closeButton is SheetNavigationButton)
        XCTAssertFalse(header.backButton.isHidden)
        XCTAssertEqual(header.bounds.height, expectedSize)
        XCTAssertEqual(header.backButton.bounds.size, CGSize(width: expectedSize, height: expectedSize))
        XCTAssertEqual(header.closeButton.bounds.size, header.backButton.bounds.size)
        XCTAssertEqual(header.backButton.frame.midY, header.closeButton.frame.midY)
        XCTAssertEqual(header.backButton.tintColor, header.closeButton.tintColor)
        XCTAssertTrue(header.backButton.point(inside: CGPoint(x: expectedSize / 2, y: -4), with: nil) || expectedSize >= 44)
        flow.close()
    }

    private func findHeader(in view: UIView) -> LinkVerificationView.Header? {
        if let header = view as? LinkVerificationView.Header { return header }
        return view.subviews.lazy.compactMap { findHeader(in: $0) }.first
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

private final class LayoutProbeView: UIView {
    private(set) var layoutCount = 0

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutCount += 1
    }
}
#endif
