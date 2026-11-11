//
//  PollingScreenSessionTests.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 11/10/26.
//

import SafariServices
import XCTest

@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet

/// The polling screen primitive: the real `PollingScreenSession` and `PollingViewController`, with a recording container
/// and a redirect presenter the test controls.
@MainActor
final class PollingScreenSessionTests: XCTestCase {
    let host = RecordingPollingHost()
    let redirectPresenter = ControlledRedirectPresenter()
    let intent = PaymentConfirmerFixtures.paymentIntent(status: "requires_action", type: "blik")
    let screen = ConfirmationMetadata.NextAction.PollingScreen(seconds: 60, intervalSeconds: 1, showsCountdown: true, deadlineField: nil, instructions: .blik)

    /// Starts the screen; `outcome` is set once it returns. Synchronous tests spin the run loop, since spinning it inside an
    /// async test would block the main actor.
    final class Run {
        var outcome: NextActionOutcome?
    }

    func perform(instructions: ResolvedNextAction.Redirect?, authenticationContext: STPAuthenticationContext? = nil) -> Run {
        let pollingScreen = ResolvedNextAction.PollingScreen(screen: screen, deadline: nil, instructions: instructions)
        let context = authenticationContext ?? host
        let run = Run()
        Task { @MainActor [intent, redirectPresenter] in
            run.outcome = await PollingScreenSession.perform(pollingScreen, intent: intent, authenticationContext: context, redirectPresenter: redirectPresenter, poll: { nil }, didOpen: { _ in })
        }
        return run
    }

    func waitUntil(_ condition: () -> Bool, file: StaticString = #filePath, line: UInt = #line) {
        let deadline = Date(timeIntervalSinceNow: 5)
        while !condition() && Date() < deadline {
            RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
        }
        XCTAssertTrue(condition(), "Timed out", file: file, line: line)
    }

    func outcome(of run: Run) -> NextActionOutcome? {
        waitUntil { run.outcome != nil }
        return run.outcome
    }

    func testScreenWithoutAWebViewFinishesThePayment() {
        // Given BLIK's polling screen, with no instructions web view
        let run = perform(instructions: nil)

        // When the container shows the screen, with BLIK's config, and the customer cancels it
        waitUntil { !host.presented.isEmpty }
        let viewController = host.presented.first
        XCTAssertEqual(viewController?.viewModel.CTA, .Localized.blik_confirm_payment)
        XCTAssertEqual(host.safariViewControllers.count, 1)
        XCTAssertTrue(host.safariViewControllers.allSatisfy { $0 == nil }, "No web view in front of BLIK's screen")
        viewController?.didTapCancel()

        // Then the screen finishes the payment
        guard case .finished(let result, _) = outcome(of: run) else {
            return XCTFail("Expected the screen to finish the payment")
        }
        XCTAssertEqual(result, .canceled)
    }

    func testScreenFinishingFirstClosesTheWebView() {
        // Given PayNow-style instructions in a web view, with the screen behind it
        let run = perform(instructions: .init(appURL: nil, webURL: URL(string: "https://qr.example"), returnURL: nil, useWebAuthSession: false, followRedirects: false))

        // When the screen finishes while the web view is still open
        waitUntil { !host.presented.isEmpty }
        host.presented.first?.didTapCancel()

        // Then the screen's result wins and the web view is closed
        guard case .finished(let result, _) = outcome(of: run) else {
            return XCTFail("Expected the screen to finish the payment")
        }
        XCTAssertEqual(result, .canceled)
        XCTAssertTrue(redirectPresenter.closed)
    }

    func testWebViewClosingFirstLeavesTheScreenToFinish() {
        // Given instructions in a web view, with the screen behind it
        let run = perform(instructions: .init(appURL: nil, webURL: URL(string: "https://qr.example"), returnURL: nil, useWebAuthSession: false, followRedirects: false))
        waitUntil { !host.presented.isEmpty }

        // When the customer closes the web view first
        redirectPresenter.customerCloses()

        // Then the engine gets the return and the screen, which can still finish the payment
        guard case .returned(let returnType, let screen?) = outcome(of: run) else {
            return XCTFail("Expected a return with the screen")
        }
        XCTAssertEqual(returnType, .safariViewController)
        host.presented.first?.didTapCancel()
        var screenResult: PaymentSheetResult?
        Task { @MainActor in screenResult = await screen.result().0 }
        waitUntil { screenResult != nil }
        XCTAssertEqual(screenResult, .canceled)
    }

    func testStoppingTheScreenTakesItDownWithoutFinishing() {
        // Given the web view closed first and the engine has the screen
        let run = perform(instructions: .init(appURL: nil, webURL: URL(string: "https://qr.example"), returnURL: nil, useWebAuthSession: false, followRedirects: false))
        waitUntil { !host.presented.isEmpty }
        redirectPresenter.customerCloses()
        guard case .returned(_, let screen?) = outcome(of: run) else {
            return XCTFail("Expected a return with the screen")
        }
        // ...and the screen is showing
        let parent = UIViewController()
        parent.addChild(host.presented[0])

        // When the payment ends some other way, e.g. the intent was canceled
        screen.stop(dismiss: true)

        // Then the container takes the screen down
        XCTAssertEqual(host.dismissed.count, 1)
    }

    func testWithoutAPaymentSheetContainerItFails() {
        // Given an authentication context that can't host a polling screen
        let run = perform(instructions: nil, authenticationContext: PlainAuthenticationContext())

        // When the screen is performed
        guard case .finished(let result, _) = outcome(of: run) else {
            return XCTFail("Expected a failure")
        }

        // Then it fails like STPPaymentHandler outside PaymentSheet
        XCTAssertEqual(result.errorCode, STPPaymentHandlerErrorCode.unsupportedAuthenticationErrorCode.rawValue)
    }
}

/// A container that records the polling screens it's given and the ones it takes down.
final class RecordingPollingHost: NSObject, PollingScreenHosting {
    private(set) var presented: [PollingViewController] = []
    private(set) var safariViewControllers: [SFSafariViewController?] = []
    private(set) var dismissed: [UIViewController] = []
    var pollingScreenAppearance: PaymentSheet.Appearance { .default }

    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }

    func present(_ authenticationViewController: UIViewController, completion: @escaping () -> Void) {}

    func dismiss(_ authenticationViewController: UIViewController, completion: (() -> Void)?) {
        dismissed.append(authenticationViewController)
        completion?()
    }

    func presentPollingViewController(_ pollingViewController: PollingViewController, safariViewController: SFSafariViewController?) {
        presented.append(pollingViewController)
        safariViewControllers.append(safariViewController)
    }
}

final class PlainAuthenticationContext: NSObject, STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}

/// A redirect presenter that stays open until the test closes it.
@MainActor
final class ControlledRedirectPresenter: RedirectPresenting {
    private var continuation: CheckedContinuation<RedirectResult, Never>?
    private(set) var closed = false

    func redirect(
        _ redirect: ResolvedNextAction.Redirect,
        authenticationContext: STPAuthenticationContext,
        didOpen: @escaping (RedirectType) -> Void,
        didPresent: ((SFSafariViewController?) -> Void)?
    ) async -> RedirectResult {
        didOpen(.safariViewController)
        didPresent?(nil)
        return await withCheckedContinuation { continuation = $0 }
    }

    func close() {
        closed = true
        customerCloses()
    }

    func customerCloses() {
        continuation?.resume(returning: .returned(.safariViewController))
        continuation = nil
    }
}
