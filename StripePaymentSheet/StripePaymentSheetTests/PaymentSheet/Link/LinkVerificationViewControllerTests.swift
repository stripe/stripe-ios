//
//  LinkVerificationViewControllerTests.swift
//  StripePaymentSheetTests
//
//

import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import XCTest

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils
@testable @_spi(STP) import StripeUICore

#if !os(visionOS)
final class LinkVerificationViewControllerTests: STPNetworkStubbingTestCase {

    @MainActor
    func testOTPDialogsKeepBalancedHorizontalMarginsInNativeSheet() async throws {
        let originalMaxRetries = StripeAPI.maxRetries
        StripeAPI.maxRetries = 0
        defer { StripeAPI.maxRetries = originalMaxRetries }
        stub(condition: isPath("/v1/consumers/sessions/start_verification")) { _ in
            LinkVerificationTestHelpers.makeStartVerificationRateLimitResponse()
        }

        // Given the embedded OTP screen in a native Link sheet
        let context = PayWithLinkViewController.Context(
            intent: ._testValue(),
            elementsSession: ._testValue(),
            configuration: PaymentSheet.Configuration(),
            linkBrand: .link,
            shouldOfferApplePay: false,
            shouldFinishOnClose: false,
            initiallySelectedPaymentDetailsID: nil,
            callToAction: nil,
            analyticsHelper: ._testValue()
        )
        let content = PayWithLinkViewController.VerifyAccountViewController(
            linkAccount: makeSUT().linkAccount,
            context: context
        )
        let sheet = LinkNativeSheetContainerViewController(
            contentViewController: content,
            appearance: LinkUI.appearance,
            isTestMode: false,
            didCancelNative3DS2: {}
        )
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let presenter = UIViewController()
        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let presented = expectation(description: "Native Link sheet presented")

        // When UIKit lays out the sheet, including Duo's vertical navigation bar
        presenter.presentAsSheet(sheet) { presented.fulfill() }
        await fulfillment(of: [presented], timeout: 5)
        let verificationVisible = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            content.children.first?.viewIfLoaded?.subviews.contains {
                ($0 as? LinkVerificationView)?.isHidden == false
            } == true
        }, object: nil)
        await fulfillment(of: [verificationVisible], timeout: 5)
        sheet.view.layoutIfNeeded()

        for mode in [LinkVerificationView.Mode.modal, .inlineLogin] {
            // When the standalone OTP dialog is presented over the native sheet
            let dialog = makeSUT(mode: mode)
            let dialogPresented = expectation(description: "OTP dialog presented")
            sheet.present(dialog, animated: false) { dialogPresented.fulfill() }
            await fulfillment(of: [dialogPresented], timeout: 5)
            dialog.view.layoutIfNeeded()
            let dialogView = try XCTUnwrap(dialog.view.subviews.compactMap { $0 as? LinkVerificationView }.first)
            let dialogCodeFrame = dialogView.codeField.convert(dialogView.codeField.bounds, to: dialog.view)

            // Then the code field has the same padding on both sides of the dialog
            XCTAssertEqual(dialogCodeFrame.minX, LinkVerificationView.Constants.edgeMargin, accuracy: 0.5, "\(mode)")
            XCTAssertEqual(dialog.view.bounds.maxX - dialogCodeFrame.maxX, LinkVerificationView.Constants.edgeMargin, accuracy: 0.5, "\(mode)")
            let dialogDismissed = expectation(description: "OTP dialog dismissed")
            dialog.dismiss(animated: false) { dialogDismissed.fulfill() }
            await fulfillment(of: [dialogDismissed], timeout: 5)
        }
        let dismissed = expectation(description: "Native Link sheet dismissed")
        presenter.dismiss(animated: false) { dismissed.fulfill() }
        await fulfillment(of: [dismissed], timeout: 5)
    }

    @MainActor
    func testStartVerification429StopsAnimatingAndShowsError() throws {
        let originalMaxRetries = StripeAPI.maxRetries
        StripeAPI.maxRetries = 0
        defer { StripeAPI.maxRetries = originalMaxRetries }

        stub(condition: isPath("/v1/consumers/sessions/start_verification")) { _ in
            LinkVerificationTestHelpers.makeStartVerificationRateLimitResponse()
        }

        let sut = makeSUT()
        let delegate = MockLinkVerificationViewControllerDelegate { _ in
            XCTFail("Delegate should not be called — user must close the view manually")
        }
        sut.delegate = delegate

        sut.loadViewIfNeeded()
        sut.viewWillAppear(false)

        let errorDisplayedExpectation = expectation(description: "error displayed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            errorDisplayedExpectation.fulfill()
        }
        wait(for: [errorDisplayedExpectation], timeout: 2.0)

        let activityIndicator = try XCTUnwrap(
            sut.view.subviews.compactMap { $0 as? ActivityIndicator }.first
        )
        XCTAssertFalse(activityIndicator.isAnimating)

        let verificationView = try XCTUnwrap(
            sut.view.subviews.compactMap { $0 as? LinkVerificationView }.first
        )
        XCTAssertFalse(verificationView.isHidden)
        XCTAssertEqual(
            verificationView.errorMessage,
            LinkUtils.ConsumerErrorCode.consumerVerificationMaxAttemptsExceeded.localizedDescription
        )
    }
}

private extension LinkVerificationViewControllerTests {
    @MainActor
    func makeSUT(mode: LinkVerificationView.Mode = .modal) -> LinkVerificationViewController {
        let session = ConsumerSession.make(
            clientSecret: "client_secret",
            emailAddress: "jane.diaz@example.com",
            redactedFormattedPhoneNumber: "+1********55",
            unredactedPhoneNumber: nil,
            phoneNumberCountry: "US",
            verificationSessions: [],
            supportedPaymentDetailsTypes: [ParsedEnum(.card)],
            mobileFallbackWebviewParams: nil,
            currentAuthenticationLevel: .notAuthenticated,
            minimumAuthenticationLevel: .oneFactorAuth
        )
        let linkAccount = PaymentSheetLinkAccount(
            email: "jane.diaz@example.com",
            session: session,
            publishableKey: "pk_test_123",
            displayablePaymentDetails: nil,
            apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey),
            useMobileEndpoints: true,
            canSyncAttestationState: false
        )

        return LinkVerificationViewController(mode: mode, linkAccount: linkAccount)
    }
}

private final class MockLinkVerificationViewControllerDelegate: LinkVerificationViewControllerDelegate {
    private let onFinish: (LinkVerificationViewController.VerificationResult) -> Void

    init(onFinish: @escaping (LinkVerificationViewController.VerificationResult) -> Void) {
        self.onFinish = onFinish
    }

    func verificationController(
        _ controller: LinkVerificationViewController,
        didFinishWithResult result: LinkVerificationViewController.VerificationResult
    ) {
        onFinish(result)
    }
}
#endif
