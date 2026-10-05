//
//  PayWithLinkViewControllerTests.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 1/6/25.
//

import Foundation
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@_spi(STP) import StripeUICore
import XCTest
#if !os(visionOS)
class PayWithLinkViewControllerTests: XCTestCase {

    var paymentSheet: PayWithNativeLinkController!

    @MainActor
    func testNativeWalletResizesWhenPaymentPickerExpandsAndCollapses() async throws {
        // Given a presented wallet with two saved cards and a collapsed payment picker
        let (window, _, sheet, picker) = try await presentNativeWallet()
        defer {
            window.rootViewController?.dismiss(animated: false)
            window.isHidden = true
        }
        let collapsedHeight = sheet.view.bounds.height

        for animated in [true, false] {
            // When the payment row expands, including without an animation
            picker.setExpanded(true, animated: animated)
            let expanded = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                sheet.view.bounds.height > collapsedHeight + 1
            }, object: nil)

            // Then the sheet grows to make room for the saved cards and Add button
            await fulfillment(of: [expanded], timeout: 3)

            // When the row collapses, the sheet returns to its original height
            picker.setExpanded(false, animated: animated)
            let collapsed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                abs(sheet.view.bounds.height - collapsedHeight) < 1
            }, object: nil)
            await fulfillment(of: [collapsed], timeout: 3)
        }
    }

    @MainActor
    func testNativeWalletResizesWhenExpandedPaymentPickerRequiresScrolling() async throws {
        // Given a collapsed wallet whose saved payment methods exceed the available sheet height
        let (window, _, sheet, picker) = try await presentNativeWallet(paymentMethods: LinkStubs.paymentMethods())
        defer {
            window.rootViewController?.dismiss(animated: false)
            window.isHidden = true
        }
        let collapsedHeight = sheet.view.bounds.height

        // When expanding the payment row
        picker.setExpanded(true, animated: true)
        let expanded = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            sheet.view.bounds.height > collapsedHeight + 1
                && sheet.scrollView.contentSize.height > sheet.scrollView.bounds.height
        }, object: nil)

        // Then the sheet grows to its maximum and the remaining rows stay scrollable
        await fulfillment(of: [expanded], timeout: 3)
        XCTAssertLessThanOrEqual(sheet.scrollView.frame.maxY, sheet.view.bounds.maxY + 0.5)

        // ...and collapsing the picker restores the shorter sheet
        picker.setExpanded(false, animated: true)
        let collapsed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            abs(sheet.view.bounds.height - collapsedHeight) < 1
        }, object: nil)
        await fulfillment(of: [collapsed], timeout: 3)
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

        // When an error appears
        wallet.updateErrorLabel(for: NSError(domain: "test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Try again."]))
        let errorShown = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            sheet.view.bounds.height > originalHeight + 1
        }, object: nil)
        await fulfillment(of: [errorShown], timeout: 3)
        let shortErrorHeight = sheet.view.bounds.height

        // Then replacing a visible error with wrapping text also grows the sheet
        let longMessage = String(repeating: "Please check your payment details and try again. ", count: 4)
        wallet.updateErrorLabel(for: NSError(domain: "test", code: 0, userInfo: [NSLocalizedDescriptionKey: longMessage]))
        let errorGrew = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            sheet.view.bounds.height > shortErrorHeight + 1
        }, object: nil)
        await fulfillment(of: [errorGrew], timeout: 3)

        // ...and clearing the error restores the original height
        wallet.updateErrorLabel(for: nil)
        let errorHidden = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            abs(sheet.view.bounds.height - originalHeight) < 1
        }, object: nil)
        await fulfillment(of: [errorHidden], timeout: 3)
    }

    @MainActor
    func testNativeWalletResizesWhenCVCRecollectionChanges() async throws {
        // Given a presented wallet whose selected card does not need CVC recollection
        let (window, wallet, sheet, picker) = try await presentNativeWallet()
        defer {
            window.rootViewController?.dismiss(animated: false)
            window.isHidden = true
        }
        let originalHeight = sheet.view.bounds.height

        // When selecting a card with a failed CVC check
        wallet.paymentMethodPicker(picker, didSelectIndex: 1)
        let recollectionShown = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            sheet.view.bounds.height > originalHeight + 1
        }, object: nil)

        // Then the sheet makes room for the recollection section
        await fulfillment(of: [recollectionShown], timeout: 3)
        XCTAssertTrue(wallet.viewModel.shouldShowRecollectionSection)

        // ...and selecting the original card shrinks the sheet again
        wallet.paymentMethodPicker(picker, didSelectIndex: 0)
        let recollectionHidden = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            abs(sheet.view.bounds.height - originalHeight) < 1
        }, object: nil)
        await fulfillment(of: [recollectionHidden], timeout: 3)
        XCTAssertFalse(wallet.viewModel.shouldShowRecollectionSection)
    }

    @MainActor
    private func presentNativeWallet(
        paymentMethods: [ConsumerPaymentDetails] = Array(LinkStubs.paymentMethods().prefix(2))
    ) async throws -> (
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
            paymentMethods: paymentMethods
        )
        let sheet = LinkNativeSheetContainerViewController(
            contentViewController: wallet,
            appearance: LinkUI.appearance,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let presenter = UIViewController()
        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        let presented = expectation(description: "Native Link wallet presented")
        presenter.presentAsSheet(sheet) { presented.fulfill() }
        await fulfillment(of: [presented], timeout: 3)

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
