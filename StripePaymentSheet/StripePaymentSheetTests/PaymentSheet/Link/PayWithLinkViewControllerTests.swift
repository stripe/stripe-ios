//
//  PayWithLinkViewControllerTests.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 1/6/25.
//

import Foundation
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import XCTest
#if !os(visionOS)
class PayWithLinkViewControllerTests: XCTestCase {
    var paymentSheet: PayWithNativeLinkController!

    @MainActor
    func testAuthenticationReturnsVerifiedAccountWithoutPresenting() async {
        let previousAccount = LinkAccountContext.shared.account
        defer { LinkAccountContext.shared.account = previousAccount }
        let account = verifiedAccount()
        LinkAccountContext.shared.account = account
        let configuration = await authenticationConfiguration()
        let host = TestViewController(onPresentChild: { _ in XCTFail("Verified authentication must not present a sheet") })
        let controller = PayWithNativeLinkController(
            mode: .authentication,
            intent: ._testValue(),
            elementsSession: ._testValue(intent: ._testValue()),
            configuration: configuration,
            analyticsHelper: ._testValue()
        )
        var completionCount = 0

        controller.presentForAuthentication(
            from: host,
            content: .init(title: "Continue with Link", subtitle: "Sign in", consentAction: .clicked_button_mobile_v1),
            requestSurface: .cryptoOnramp
        ) { result in
            completionCount += 1
            guard case .success(let authenticated) = result else { return XCTFail("Expected authenticated account") }
            XCTAssertTrue(authenticated === account)
        }

        XCTAssertEqual(completionCount, 1)
    }

    @MainActor
    func testAuthenticationRejectsPaymentWebFallbackOnce() async {
        let previousAccount = LinkAccountContext.shared.account
        defer { LinkAccountContext.shared.account = previousAccount }
        LinkAccountContext.shared.account = nil
        let configuration = await authenticationConfiguration()
        let controller = PayWithLinkViewController(
            intent: ._testValue(),
            linkAccount: nil,
            elementsSession: ._testValue(intent: ._testValue()),
            configuration: configuration,
            analyticsHelper: ._testValue(),
            authentication: .init(title: "Continue with Link", subtitle: "Sign in", consentAction: .clicked_button_mobile_v1)
        )
        let delegate = AuthenticationDelegate()
        controller.payWithLinkDelegate = delegate

        controller.bailToWebFlow()
        controller.bailToWebFlow()

        XCTAssertEqual(delegate.results.count, 1)
        guard case .failed(let error)? = delegate.results.first else { return XCTFail("Expected authentication failure") }
        XCTAssertEqual(error as? LinkController.IntegrationError, .missingAppAttestation)
        XCTAssertTrue(delegate.authenticatedAccounts.isEmpty)
    }

    @MainActor
    func testAuthenticationFinishesWithTheVerifiedAccountInsteadOfLoadingTheWallet() async {
        // Given Link's sheet is open for authentication
        let previousAccount = LinkAccountContext.shared.account
        defer { LinkAccountContext.shared.account = previousAccount }
        LinkAccountContext.shared.account = nil
        let controller = PayWithLinkViewController(
            intent: ._testValue(),
            linkAccount: nil,
            elementsSession: ._testValue(intent: ._testValue()),
            configuration: await authenticationConfiguration(),
            analyticsHelper: ._testValue(),
            authentication: .init(title: "Continue with Link", subtitle: "Sign in", consentAction: .clicked_button_mobile_v1)
        )
        let delegate = AuthenticationDelegate()
        controller.payWithLinkDelegate = delegate

        // When the user's session is verified
        let account = verifiedAccount()
        controller.accountUpdated(account)

        // Then it reports the authenticated account and stops taking input
        XCTAssertEqual(delegate.authenticatedAccounts.count, 1)
        XCTAssertTrue(delegate.authenticatedAccounts.first === account)
        XCTAssertTrue(delegate.results.isEmpty)
        XCTAssertFalse(controller.view.isUserInteractionEnabled)
    }

    private func verifiedAccount() -> PaymentSheetLinkAccount {
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

    @MainActor
    private func authenticationConfiguration() async -> PaymentSheet.Configuration {
        let apiClient = STPAPIClient(publishableKey: "pk_test_authentication")
        let attestService = MockAppAttestService()
        await attestService.setShouldFailKeygenWithError(NSError(domain: "test", code: 1))
        apiClient.stripeAttest = StripeAttest(
            appAttestService: attestService,
            appAttestBackend: MockAttestBackend(),
            apiClient: apiClient
        )
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.apiClient = apiClient
        return configuration
    }

    @MainActor
    func testBailsToWebFlowWhenAttestationFails() async {
        // Set up a mock STPAPIClient with a mocked attestation backend
        let apiClient = STPAPIClient(publishableKey: "pk_live_abc123")
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        let mockAttestBackend = MockAttestBackend()
        let mockAttestService = MockAppAttestService()
        let mockStripeAttest = StripeAttest(appAttestService: mockAttestService, appAttestBackend: mockAttestBackend, apiClient: apiClient)
        apiClient.stripeAttest = mockStripeAttest
        config.apiClient = apiClient

        // Always fail attestation, forcing us back to the web flow
        await mockAttestService.setShouldFailKeygenWithError(NSError(domain: "test", code: 1))

        let exp = expectation(description: "SFAuthenticationViewController presented")
        // Create a TestViewController, which will call our custom block when a child VC is presented.
        let hostVC = TestViewController(onPresentChild: { vc in
            // Ensure the SFWebAuthenticationSession view controller is being presented over us.
            // SFAuthenticationViewController is private, so this is a bit hacky.
            // Should be okay for a test — if it breaks, we'd just need to replace it with the new name for SFAuthenticationViewController.
            if String(describing: type(of: vc)) == "SFAuthenticationViewController" {
                exp.fulfill()
            }
        })
        // We need a real window to present the test VC
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hostVC
        window.makeKeyAndVisible()

        let payWithNativeLinkController = PayWithNativeLinkController(
            mode: .full,
            intent: ._testValue(),
            elementsSession: ._testValue(intent: ._testValue()),
            configuration: config,
            analyticsHelper: ._testValue()
        )

        // Now make the fake PayWithLinkViewController and present it
        let vc = PayWithLinkViewController(intent: ._testValue(), linkAccount: nil, elementsSession: ._testValue(intent: ._testValue()), configuration: config, analyticsHelper: ._testValue())
        vc.payWithLinkDelegate = paymentSheet
        hostVC.present(vc, animated: true, completion: {})

        payWithNativeLinkController.presentAsBottomSheet(from: vc, shouldOfferApplePay: false, shouldFinishOnClose: false, completion: { _, _, _ in })

        // Wait a bit: Attestation should be attempted, but immediately fail.
        await fulfillment(of: [exp], timeout: 2.0)
    }
}

@MainActor
private final class AuthenticationDelegate: PayWithLinkViewControllerDelegate {
    var results: [PaymentSheetResult] = []
    var authenticatedAccounts: [PaymentSheetLinkAccount] = []

    func payWithLinkViewControllerDidFinish(_ payWithLinkViewController: PayWithLinkViewController, result: PaymentSheetResult, deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?) {
        results.append(result)
    }

    func payWithLinkViewControllerDidConfirm(_ payWithLinkViewController: PayWithLinkViewController, intent: Intent, elementsSession: STPElementsSession, with paymentOption: PaymentOption, completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void) {
        XCTFail("Authentication must not confirm a payment")
    }

    func payWithLinkViewControllerDidCancel(_ payWithLinkViewController: PayWithLinkViewController, shouldReturnToPaymentSheet: Bool) {
        XCTFail("Authentication must not cancel on its own")
    }

    func payWithLinkViewControllerDidFinish(_ payWithLinkViewController: PayWithLinkViewController, confirmOption: PaymentSheet.LinkConfirmOption) {
        XCTFail("Authentication must not select a payment method")
    }

    func payWithLinkViewControllerShouldCancel3DS2ChallengeFlow(_ payWithLinkViewController: PayWithLinkViewController) {
        XCTFail("Authentication must not start a payment challenge")
    }

    func payWithLinkViewControllerDidAuthenticate(_ payWithLinkViewController: PayWithLinkViewController, linkAccount: PaymentSheetLinkAccount) {
        authenticatedAccounts.append(linkAccount)
    }
}

// This just exists for the above test, it calls a block when a VC is presented
class TestViewController: UIViewController {
    let onPresentChild: (UIViewController) -> Void

    init(onPresentChild: @escaping (UIViewController) -> Void) {
        self.onPresentChild = onPresentChild
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        onPresentChild(viewControllerToPresent)
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
}
#endif
