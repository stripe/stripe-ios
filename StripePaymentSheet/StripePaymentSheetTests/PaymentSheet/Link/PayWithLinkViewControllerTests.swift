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
@_spi(STP) import StripeUICore
import XCTest
#if !os(visionOS)
class PayWithLinkViewControllerTests: XCTestCase {

    var paymentSheet: PayWithNativeLinkController!

    @MainActor
    func testNativeWalletResizesWhenPaymentPickerExpandsAndCollapses() async throws {
        // Given a presented wallet with two saved cards and a collapsed payment picker
        let (window, wallet, sheet, picker) = try await presentNativeWallet()
        defer {
            window.rootViewController?.dismiss(animated: false)
            window.isHidden = true
        }
        let collapsedHeight = sheet.view.bounds.height
        let collapsedContentHeight = NativeSheetLayoutTestHelper.fittedHeight(of: wallet.view, in: sheet)

        for animated in [true, false] {
            // When the payment row expands, including without an animation
            picker.setExpanded(true, animated: animated)
            try await NativeSheetLayoutTestHelper.waitForContentToFit(in: sheet, content: wallet.view, minimumContentHeight: collapsedContentHeight + 1)

            // Then the sheet grows by the measured height of the saved cards and Add button
            let pickerHeight = NativeSheetLayoutTestHelper.fittedHeight(of: wallet.view, in: sheet) - collapsedContentHeight
            XCTAssertEqual(sheet.view.bounds.height - collapsedHeight, pickerHeight, accuracy: 1)

            // When the row collapses, the sheet returns to its original height
            picker.setExpanded(false, animated: animated)
            try await NativeSheetLayoutTestHelper.waitForContentToFit(in: sheet, content: wallet.view, expectedContentHeight: collapsedContentHeight)
            XCTAssertEqual(sheet.view.bounds.height, collapsedHeight, accuracy: 1)
        }
    }

    @MainActor
    func testNativeWalletResizesWhenErrorTextChanges() async throws {
        // Given a presented wallet with no error
        let (window, wallet, sheet, _) = try await presentNativeWallet()
        defer {
            window.rootViewController?.dismiss(animated: false)
            window.isHidden = true
        }
        let originalHeight = sheet.view.bounds.height
        let originalContentHeight = NativeSheetLayoutTestHelper.fittedHeight(of: wallet.view, in: sheet)

        // When an error appears
        wallet.updateErrorLabel(for: NSError(domain: "test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Try again."]))
        try await NativeSheetLayoutTestHelper.waitForContentToFit(in: sheet, content: wallet.view, minimumContentHeight: originalContentHeight + 1)
        let shortErrorHeight = sheet.view.bounds.height
        let shortErrorContentHeight = NativeSheetLayoutTestHelper.fittedHeight(of: wallet.view, in: sheet)
        XCTAssertEqual(shortErrorHeight - originalHeight, shortErrorContentHeight - originalContentHeight, accuracy: 1)

        // Then replacing a visible error with wrapping text also grows the sheet
        let longMessage = String(repeating: "Please check your payment details and try again. ", count: 8)
        wallet.updateErrorLabel(for: NSError(domain: "test", code: 0, userInfo: [NSLocalizedDescriptionKey: longMessage]))
        try await NativeSheetLayoutTestHelper.waitForContentToFit(in: sheet, content: wallet.view, minimumContentHeight: shortErrorContentHeight + 1)
        let longErrorContentHeight = NativeSheetLayoutTestHelper.fittedHeight(of: wallet.view, in: sheet)
        XCTAssertEqual(sheet.view.bounds.height - shortErrorHeight, longErrorContentHeight - shortErrorContentHeight, accuracy: 1)

        // ...and clearing the error restores the original height
        wallet.updateErrorLabel(for: nil)
        try await NativeSheetLayoutTestHelper.waitForContentToFit(in: sheet, content: wallet.view, expectedContentHeight: originalContentHeight)
        XCTAssertEqual(sheet.view.bounds.height, originalHeight, accuracy: 1)
    }

    @MainActor
    private func presentNativeWallet() async throws -> (
        UIWindow, PayWithLinkViewController.WalletViewController,
        NativeSheetContainerViewController, LinkPaymentMethodPicker
    ) {
        guard #available(iOS 16.0, *) else { throw XCTSkip("Content-sized detents require iOS 16.") }
        let (intent, elementsSession) = try PayWithLinkTestHelpers.makePaymentIntentAndElementsSession()
        let wallet = PayWithLinkViewController.WalletViewController(
            linkAccount: LinkStubs.account(),
            context: .init(
                intent: intent,
                elementsSession: elementsSession,
                configuration: PaymentSheet.Configuration(),
                linkBrand: .link,
                shouldOfferApplePay: false,
                shouldFinishOnClose: false,
                canContinueWithoutLink: false,
                initiallySelectedPaymentDetailsID: nil,
                callToAction: nil,
                supportedPaymentMethodTypes: [.card],
                analyticsHelper: ._testValue()
            ),
            paymentMethods: Array(LinkStubs.paymentMethods().prefix(2))
        )
        let sheet = LinkNativeSheetContainerViewController(
            contentViewController: wallet,
            appearance: LinkUI.appearance,
            didCancelNative3DS2: {}
        )
        // A cold test-host launch may still be connecting its window scene.
        let sceneConnected = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            UIApplication.shared.connectedScenes.contains { $0 is UIWindowScene }
        }, object: nil)
        await fulfillment(of: [sceneConnected], timeout: 5)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let presenter = UIViewController()
        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        let presented = expectation(description: "Native Link wallet presented")
        presenter.presentAsSheet(sheet) { presented.fulfill() }
        await fulfillment(of: [presented], timeout: 3)
        try await NativeSheetLayoutTestHelper.waitForContentToFit(in: sheet, content: wallet.view)

        // Find the actual wallet picker without adding a production accessor for the test.
        var pending = [wallet.view!]
        var picker: LinkPaymentMethodPicker?
        while let view = pending.popLast() {
            if let paymentPicker = view as? LinkPaymentMethodPicker {
                picker = paymentPicker
                break
            }
            pending.append(contentsOf: view.subviews)
        }
        let paymentPicker = try XCTUnwrap(picker)
        XCTAssertTrue(paymentPicker.collapsable)
        return (window, wallet, sheet, paymentPicker)
    }

    @MainActor
    func testWalletPushesConfigureLinkNavigationInBothContainers() async throws {
        guard UIDevice.current.userInterfaceIdiom == .phone, !SheetImplementationResolver.isRequiredForDevice else {
            throw XCTSkip("Both container implementations require a non-Duo phone.")
        }
        await AddressSpecProvider.shared.loadAddressSpecs()
        let previousAccount = LinkAccountContext.shared.account
        defer { LinkAccountContext.shared.account = previousAccount }

        for usesNativeSheet in [false, true] {
            for entryPoint in ["addCard", "editCard", "billingDetails"] {
                // Given a Link wallet in each sheet implementation, with interaction temporarily disabled
                let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
                let elementsSession = STPElementsSession._testValue(
                    flags: ["elements_mobile_ios_native_sheet_enabled": usesNativeSheet]
                )
                let apiClient = STPAPIClient(publishableKey: "pk_test_abc123")
                apiClient.stripeAttest = StripeAttest(
                    appAttestService: MockAppAttestService(),
                    appAttestBackend: MockAttestBackend(),
                    apiClient: apiClient
                )
                var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
                configuration.apiClient = apiClient
                if entryPoint == "billingDetails" {
                    configuration.billingDetailsCollectionConfiguration.address = .full
                }
                let coordinator = PayWithLinkViewController(
                    intent: intent,
                    linkAccount: nil,
                    elementsSession: elementsSession,
                    configuration: configuration,
                    nativeSheetPresentation: SheetImplementationResolver(elementsSession: elementsSession),
                    analyticsHelper: ._testValue(),
                    supportedPaymentMethodTypes: [.card]
                )
                let sheet = coordinator.sheetContainer
                XCTAssertEqual(sheet is NativeSheetContainerViewController, usesNativeSheet)
                let initialContent = try XCTUnwrap(sheet.contentStack.first as? PayWithLinkViewController.BaseViewController)
                let paymentMethod = LinkStubs.paymentMethods()[LinkStubs.PaymentMethodIndices.card]
                let wallet = PayWithLinkViewController.WalletViewController(
                    linkAccount: LinkStubs.account(),
                    context: initialContent.context,
                    paymentMethods: [paymentMethod]
                )
                coordinator.setViewControllers([wallet])
                let walletVisible = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                    wallet.parent === sheet && wallet.view.alpha == 1
                }, object: nil)
                await fulfillment(of: [walletVisible], timeout: 3)
                sheet.setUserInteractionEnabled(false)

                // When the wallet opens Add Card, Edit Card, or missing billing details through its real entry point
                switch entryPoint {
                case "addCard":
                    wallet.paymentDetailsPickerDidTapOnAddPayment(LinkPaymentMethodPicker(), sourceRect: .zero)
                case "editCard":
                    let editAction = try XCTUnwrap(wallet.paymentMethodPicker(LinkPaymentMethodPicker(), menuActionsForItemAt: 0).first {
                        $0.title == String.Localized.update_card
                    })
                    editAction.action()
                default:
                    wallet.confirm()
                    let billingDetailsPushed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                        sheet.contentStack.first !== wallet
                    }, object: nil)
                    await fulfillment(of: [billingDetailsPushed], timeout: 3)
                }

                // Then the pushed screen has Link actions and an enabled Back button before it is displayed
                let pushedContent = try XCTUnwrap(sheet.contentStack.first as? PayWithLinkViewController.BaseViewController)
                XCTAssertFalse(pushedContent === wallet, entryPoint)
                XCTAssertIdentical(pushedContent.coordinator, coordinator, entryPoint)
                XCTAssertIdentical(pushedContent.navigationBar.delegate, coordinator, entryPoint)
                XCTAssertTrue(sheet.view.isUserInteractionEnabled, entryPoint)
                let backButton = try XCTUnwrap(pushedContent.navigationBar.leadingElement.subviews.first {
                    $0.accessibilityIdentifier == "UIButton.Back"
                } as? UIButton)
                XCTAssertFalse(backButton.isHidden, entryPoint)
                XCTAssertTrue(backButton.isEnabled, entryPoint)
                let pushedVisible = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                    pushedContent.parent === sheet && pushedContent.view.alpha == 1
                }, object: nil)
                await fulfillment(of: [pushedVisible], timeout: 3)

                // When Back is tapped, its delegate restores the wallet and detaches the pushed controller
                backButton.sendActions(for: .touchUpInside)
                XCTAssertIdentical(sheet.contentStack.first, wallet, entryPoint)
                let popped = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                    pushedContent.parent == nil && wallet.view.alpha == 1
                }, object: nil)
                await fulfillment(of: [popped], timeout: 3)
            }
        }
    }

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
        XCTAssertFalse(controller.sheetContainer.view.isUserInteractionEnabled)
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
        hostVC.present(vc.sheetContainer, animated: true, completion: {})

        payWithNativeLinkController.presentAsSheet(from: vc.sheetContainer, shouldOfferApplePay: false, shouldFinishOnClose: false, completion: { _, _, _ in })

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
