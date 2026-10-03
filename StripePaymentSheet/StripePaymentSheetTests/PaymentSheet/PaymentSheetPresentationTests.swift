//
//  PaymentSheetPresentationTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 8/10/26.
//

@_spi(STP) @testable import StripePayments
@_spi(STP) @_spi(AppearanceAPIAdditionsPreview) @testable import StripePaymentSheet
@_spi(STP) import StripeUICore
import UIKit
import XCTest

#if !os(visionOS)
final class PaymentSheetPresentationTests: XCTestCase {

    @MainActor
    func testNativeSheetResizesToScrollableContentAtRegularWidth() async throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Trait overrides require iOS 17.") }
        // Given the regular-width presentation used by an unfolded phone
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let presenter = UIViewController()
        presenter.traitOverrides.horizontalSizeClass = .regular
        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        await AddressSpecProvider.shared.loadAddressSpecs()
        let paymentMethodTypes: [STPPaymentMethodType] = [
            .card, .cashApp, .klarna, .affirm, .USBankAccount, .afterpayClearpay, .payPal,
            .revolutPay, .alipay, .bancontact, .EPS, .iDEAL, .SEPADebit, .OXXO,
        ]
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: paymentMethodTypes),
            elementsSession: ._testValue(paymentMethodTypes: paymentMethodTypes.compactMap { STPPaymentMethod.string(from: $0) }),
            savedPaymentMethods: [],
            paymentMethodTypes: paymentMethodTypes.map { .stripe($0) },
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .vertical
        )
        var configuration = PaymentSheet.Configuration()
        configuration.applePay = nil
        configuration.link = .init(display: .never)
        let content = PaymentSheetVerticalViewController(
            configuration: configuration,
            loadResult: loadResult,
            isFlowController: false,
            analyticsHelper: ._testValue()
        )
        let paymentSheet = PaymentSheet(paymentIntentClientSecret: "pi_test_secret_test", configuration: configuration)
        let sheet = NativeSheetContainerViewController(
            contentViewController: paymentSheet.loadingViewController,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        let presented = expectation(description: "Regular-width native sheet presented")

        // When replacing the loading spinner with content taller than the available sheet
        presenter.presentAsSheet(sheet) { presented.fulfill() }
        await fulfillment(of: [presented], timeout: 3)
        let navigationController = try XCTUnwrap(presenter.presentedViewController as? UINavigationController)
        let sheetPresentationController = try XCTUnwrap(navigationController.sheetPresentationController)
        XCTAssertEqual(sheetPresentationController.selectedDetentIdentifier, NativeSheetContainerViewController.contentDetentIdentifier)
        let contentVisible = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            content.view.window != nil && content.view.alpha == 1
        }, object: nil)
        sheet.setViewControllers([content])

        // Then resizing completes, the viewport stays capped, and the app can dismiss the sheet
        await fulfillment(of: [contentVisible], timeout: 3)
        XCTAssertGreaterThan(sheet.scrollView.contentSize.height, sheet.scrollView.bounds.height)
        XCTAssertLessThanOrEqual(sheet.scrollView.frame.maxY, sheet.view.bounds.maxY + 0.5)
        let dismissed = expectation(description: "Regular-width native sheet dismissed")
        presenter.dismiss(animated: false) { dismissed.fulfill() }
        await fulfillment(of: [dismissed], timeout: 3)
    }

    @MainActor
    func testNativeGlassPresentationFadesBackground() async throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Liquid Glass requires iOS 26.") }
        guard !UIAccessibility.isReduceMotionEnabled else { throw XCTSkip("Presentation animations require Reduce Motion to be off.") }
        // Given real payment content using native sheets and Liquid Glass
        await AddressSpecProvider.shared.loadAddressSpecs()
        let previousOverride = PaymentSheet.NativeSheetFeatureFlags.nativeSheetEnabledOverride
        PaymentSheet.NativeSheetFeatureFlags.nativeSheetEnabledOverride = true
        defer { PaymentSheet.NativeSheetFeatureFlags.nativeSheetEnabledOverride = previousOverride }
        var appearance = PaymentSheet.Appearance.default
        appearance.applyLiquidGlass()
        for variant in ["horizontal", "vertical", "embedded"] {
            let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
            let presenter = UIViewController()
            presenter.view.backgroundColor = .white
            let window = UIWindow(windowScene: scene)
            window.frame = UIScreen.main.bounds
            window.rootViewController = presenter
            window.makeKeyAndVisible()
            defer { window.isHidden = true }
            try await Task.sleep(nanoseconds: 200_000_000)
            var flowController: PaymentSheet.FlowController?
            var embeddedElement: EmbeddedPaymentElement?

            // When opening the FlowController picker or Embedded's card form
            let loadResult = PaymentSheetLoader.LoadResult(
                intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
                elementsSession: ._testValue(paymentMethodTypes: ["card"]),
                savedPaymentMethods: [],
                paymentMethodTypes: [.stripe(.card)],
                paymentMethodMessagingPromotionsHelper: ._testValue(),
                paymentMethodOrientation: variant == "horizontal" ? .horizontal : .vertical
            )
            var configuration = PaymentSheet.Configuration()
            configuration.appearance = appearance
            configuration.applePay = nil
            configuration.link = .init(display: .never)
            if variant == "embedded" {
                var embeddedConfiguration = EmbeddedPaymentElement.Configuration()
                embeddedConfiguration.appearance = appearance
                let element = EmbeddedPaymentElement(configuration: embeddedConfiguration, loadResult: loadResult, analyticsHelper: ._testValue())
                embeddedElement = element
                element.presentingViewController = presenter
                presenter.view.addSubview(element.view)
                element.view.frame = presenter.view.bounds
                element.embeddedPaymentMethodsView.didTap(rowButton: element.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Card"))
            } else {
                flowController = PaymentSheet.FlowController(configuration: configuration, loadResult: loadResult, analyticsHelper: ._testValue())
                flowController?.presentPaymentOptions(from: presenter, completion: {})
            }

            // Then the rendered background starts lighter and darkens during the opening animation.
            try await Task.sleep(nanoseconds: 25_000_000)
            let navigationController = try XCTUnwrap(presenter.presentedViewController as? UINavigationController)
            XCTAssertTrue(navigationController.viewControllers.first is NativeSheetContainerViewController)
            var pending = [window as UIView]
            var dimmingLayer: CALayer?
            while let view = pending.popLast() {
                // Search UIKit's presentation chrome, not the payment form's own animations.
                guard view !== navigationController.view, view !== presenter.view else { continue }
                if let alpha = view.layer.backgroundColor?.alpha, alpha > 0, alpha < 1,
                   view.layer.animation(forKey: "backgroundColor") != nil {
                    dimmingLayer = view.layer
                    break
                }
                pending.append(contentsOf: view.subviews)
            }
            let layer = try XCTUnwrap(dimmingLayer, "Missing dimming animation for \(variant)")
            let targetAlpha = try XCTUnwrap(layer.backgroundColor?.alpha)
            let initialAlpha = try XCTUnwrap(layer.presentation()?.backgroundColor?.alpha)
            XCTAssertLessThan(initialAlpha, targetAlpha * 0.75, "\(variant) dimmed immediately")
            try await Task.sleep(nanoseconds: 75_000_000)
            let laterAlpha = try XCTUnwrap(layer.presentation()?.backgroundColor?.alpha)
            XCTAssertGreaterThan(laterAlpha, initialAlpha + 0.01, "\(variant) did not fade")

            // Let UIKit finish presenting before dismissing this variant.
            try await Task.sleep(nanoseconds: 500_000_000)
            let dismissed = expectation(description: "Dismissed \(variant)")
            presenter.dismiss(animated: false) { dismissed.fulfill() }
            await fulfillment(of: [dismissed], timeout: 3)
            withExtendedLifetime((flowController, embeddedElement)) {}
        }
    }

    @MainActor
    func testPreparingNativeSheetDoesNotResizePresentationHost() {
        // Given a navigation controller whose bounds differ from the content's available width
        let sheet = NativeSheetContainerViewController(
            contentViewController: MeasuredSheetContentViewController(),
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        let navigationController = UINavigationController(rootViewController: sheet)
        navigationController.view.frame = CGRect(x: 0, y: 0, width: 1024, height: 800)

        // When measuring content before presentation
        sheet.prepareForPresentation(in: 375)

        // Then only the content is resized; UIKit retains control of the presentation host's layout
        XCTAssertEqual(sheet.view.bounds.width, 375)
        XCTAssertEqual(navigationController.view.bounds.width, 1024)
    }

    @MainActor
    func testPresentAsSheetUsesNativeSheetBehavior() throws {
        // Given
        let contentViewController = NativeSheetStubContentViewController()
        let sheetViewController = NativeSheetContainerViewController(
            contentViewController: contentViewController,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        var presentedViewController: UIViewController?
        let presentingViewController = PresentationCapturingViewController {
            presentedViewController = $0
        }

        // When
        presentingViewController.presentAsSheet(sheetViewController)

        // Then
        let navigationController = try XCTUnwrap(presentedViewController as? UINavigationController)
        XCTAssertIdentical(navigationController.topViewController, sheetViewController)
        XCTAssertIdentical(navigationController.bottomSheetController, sheetViewController)
        XCTAssertIdentical(contentViewController.navigationBar.systemNavigationItem, sheetViewController.navigationItem)
        // UIKit may return the concrete style that its default automatic presentation resolves to.
        XCTAssertEqual(navigationController.modalPresentationStyle, UINavigationController().modalPresentationStyle)
        XCTAssertTrue(navigationController.isModalInPresentation)

        let sheetPresentationController = try XCTUnwrap(navigationController.sheetPresentationController)
        XCTAssertIdentical(sheetPresentationController.delegate, sheetViewController)
        XCTAssertEqual(sheetPresentationController.detents.count, 1)
        if #available(iOS 16.0, *) {
            XCTAssertEqual(
                sheetPresentationController.detents.first?.identifier,
                NativeSheetContainerViewController.contentDetentIdentifier
            )
            XCTAssertEqual(
                sheetPresentationController.selectedDetentIdentifier,
                NativeSheetContainerViewController.contentDetentIdentifier
            )
        } else {
            XCTAssertEqual(sheetPresentationController.selectedDetentIdentifier, .large)
        }
        XCTAssertFalse(sheetPresentationController.prefersGrabberVisible)
        XCTAssertEqual(sheetPresentationController.preferredCornerRadius, sheetViewController.appearance.sheetCornerRadius)
        XCTAssertFalse(sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge)
        XCTAssertFalse(sheetPresentationController.prefersEdgeAttachedInCompactHeight)
    }

    @MainActor
    func testNativeSheetUsesItsOwnCornerRadius() throws {
        // Given a different legacy sheet's global appearance
        let previousAppearance = BottomSheetTransitioningDelegate.appearance
        defer { BottomSheetTransitioningDelegate.appearance = previousAppearance }
        BottomSheetTransitioningDelegate.appearance.sheetCornerRadius = 48
        var presentedViewController: UIViewController?
        let presenter = PresentationCapturingViewController { presentedViewController = $0 }

        for radius: CGFloat in [0, 24] {
            var appearance = PaymentSheet.Appearance.default
            appearance.sheetCornerRadius = radius
            let sheet = NativeSheetContainerViewController(
                contentViewController: NativeSheetStubContentViewController(),
                appearance: appearance,
                isTestMode: true,
                didCancelNative3DS2: {}
            )

            // When presenting a native sheet
            presenter.presentAsSheet(sheet)

            // Then its own configured radius is applied, independently of the legacy global
            let presentationController = try XCTUnwrap(presentedViewController?.sheetPresentationController)
            XCTAssertEqual(presentationController.preferredCornerRadius, radius)
        }
    }

    @MainActor
    func testNativeSheetUsesOverriddenCornerRadius() throws {
        let sheet = LinkCornerRadiusSheetViewController(
            contentViewController: NativeSheetStubContentViewController(),
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )

        var presentedViewController: UIViewController?
        PresentationCapturingViewController { presentedViewController = $0 }.presentAsSheet(sheet)

        XCTAssertEqual(try XCTUnwrap(presentedViewController?.sheetPresentationController).preferredCornerRadius, LinkUI.largeCornerRadius)
    }

    @MainActor
    func testContentDetentMeasuresSystemNavigationBar() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("Content-sized detents are used on iOS 16 and later.") }
        // A taller legacy bar must not affect sizing once UIKit owns the navigation bar.
        let initialContent = MeasuredSheetContentViewController(contentHeight: 200, navigationBarHeight: 70)
        let sheet = NativeSheetContainerViewController(
            contentViewController: initialContent,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        let navigationController = UINavigationController(rootViewController: sheet)
        navigationController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 800)
        sheet.prepareForPresentation(in: 375)
        let context = SheetDetentResolutionContext()
        let navigationBarHeight = navigationController.navigationBar.sizeThatFits(CGSize(width: 375, height: 0)).height

        XCTAssertEqual(try XCTUnwrap(sheet.contentSizedDetent.resolvedValue(in: context)), 200 + navigationBarHeight, accuracy: 0.5)

        // When moving to content with a different custom bar, only the UIKit bar contributes height
        sheet.pushContentViewController(MeasuredSheetContentViewController(contentHeight: 300, navigationBarHeight: 90))
        sheet.view.layoutIfNeeded()

        XCTAssertEqual(try XCTUnwrap(sheet.contentSizedDetent.resolvedValue(in: context)), 300 + navigationBarHeight, accuracy: 0.5)
        XCTAssertNil(initialContent.navigationBar.systemNavigationItem)
    }

    @MainActor
    func testNativeGlassContentScrollsBehindNavigationBarWithDefaultAppearance() throws {
        guard #available(iOS 26.0, *), LiquidGlassDetector.isEnabledInMerchantApp else {
            throw XCTSkip("The merchant app must enable Liquid Glass.")
        }
        // Given a glass-enabled app whose payment form still uses the default plain appearance
        let appearance = PaymentSheet.Appearance.default
        let initialContent = MeasuredSheetContentViewController(contentHeight: 1000, navigationBarHeight: 90, appearance: appearance)
        let sheet = NativeSheetContainerViewController(
            contentViewController: initialContent,
            appearance: appearance,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        let navigationController = UINavigationController(rootViewController: sheet)
        navigationController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 800)
        navigationController.view.layoutIfNeeded()
        sheet.prepareForPresentation(in: 375)

        // Then the scroll surface covers the header, while its inset keeps content below the controls at rest
        XCTAssertGreaterThan(sheet.view.safeAreaInsets.top, 0)
        XCTAssertEqual(sheet.scrollView.frame.minY, sheet.view.bounds.minY, accuracy: 0.5)
        XCTAssertEqual(initialContent.view.convert(.zero, to: sheet.view).y, sheet.view.safeAreaLayoutGuide.layoutFrame.minY, accuracy: 0.5)

        // When scrolling, the content moves behind the header and restoring the top respects its inset
        sheet.scrollView.setContentOffset(.zero, animated: false)
        XCTAssertLessThan(initialContent.view.convert(.zero, to: sheet.view).y, sheet.view.safeAreaLayoutGuide.layoutFrame.minY)
        sheet.contentOffsetPercentage = 1
        XCTAssertEqual(initialContent.view.convert(initialContent.view.bounds, to: sheet.view).maxY, sheet.scrollView.frame.maxY, accuracy: 0.5)
        sheet.contentOffsetPercentage = 0
        XCTAssertEqual(initialContent.view.convert(.zero, to: sheet.view).y, sheet.view.safeAreaLayoutGuide.layoutFrame.minY, accuracy: 0.5)

        // When replacing the content, the new form starts below the same native controls
        let replacement = MeasuredSheetContentViewController(contentHeight: 200, navigationBarHeight: 110, appearance: appearance)
        sheet.pushContentViewController(replacement)
        sheet.view.layoutIfNeeded()

        XCTAssertEqual(replacement.view.convert(.zero, to: sheet.view).y, sheet.view.safeAreaLayoutGuide.layoutFrame.minY, accuracy: 0.5)
        let navigationBarHeight = navigationController.navigationBar.sizeThatFits(CGSize(width: 375, height: 0)).height
        XCTAssertEqual(try XCTUnwrap(sheet.contentSizedDetent.resolvedValue(in: SheetDetentResolutionContext())), 200 + navigationBarHeight, accuracy: 0.5)
    }

    @MainActor
    func testNativeSolidNavigationBarShowsShadowOnlyAfterScrolling() throws {
        guard !LiquidGlassDetector.isEnabledInMerchantApp else { throw XCTSkip("The merchant app must use compatibility styling.") }
        // Given a native sheet with enough content to scroll
        let sheet = NativeSheetContainerViewController(
            contentViewController: MeasuredSheetContentViewController(contentHeight: 1000),
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        var presentedViewController: UIViewController?
        PresentationCapturingViewController { presentedViewController = $0 }.presentAsSheet(sheet)
        let navigationController = try XCTUnwrap(presentedViewController as? UINavigationController)
        navigationController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 800)
        navigationController.view.layoutIfNeeded()
        sheet.view.layoutIfNeeded()
        let navigationBar = navigationController.navigationBar

        // Then the solid header has no separator or shadow at rest
        XCTAssertEqual(navigationBar.standardAppearance.backgroundColor, sheet.appearance.colors.background)
        XCTAssertEqual(navigationBar.standardAppearance.shadowColor, .clear)
        XCTAssertEqual(navigationBar.layer.shadowOpacity, 0)

        // When scrolling away from the top, a soft shadow appears and disappears when returning
        sheet.scrollView.setContentOffset(CGPoint(x: 0, y: 40), animated: false)
        XCTAssertGreaterThan(navigationBar.layer.shadowOpacity, 0)
        sheet.scrollView.setContentOffset(.zero, animated: false)
        XCTAssertEqual(navigationBar.layer.shadowOpacity, 0)
    }

    @MainActor
    func testEarlyContentUpdatesWaitForPresentationAndCoalesce() async throws {
        let initialContent = MeasuredSheetContentViewController()
        let skippedContent = MeasuredSheetContentViewController()
        let finalContent = MeasuredSheetContentViewController()
        let sheet = NativeSheetContainerViewController(
            contentViewController: initialContent,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        let presenter = UIViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let presented = expectation(description: "Native sheet presentation completed")
        let updated = expectation(description: "Final content appeared once")
        updated.assertForOverFulfill = true
        var presentationCompleted = false
        finalContent.onDidAppear = {
            XCTAssertTrue(presentationCompleted)
            updated.fulfill()
        }

        // When loading changes the content twice during a real UIKit presentation
        presenter.presentAsSheet(sheet) {
            presentationCompleted = true
            presented.fulfill()
        }
        XCTAssertTrue(sheet.rootParent.isBeingPresented)
        sheet.setViewControllers([skippedContent])
        sheet.setViewControllers([finalContent])

        // Then the appearing child remains attached until UIKit has finished its transition
        XCTAssertIdentical(initialContent.parent, sheet)
        XCTAssertNil(skippedContent.parent)
        XCTAssertNil(finalContent.parent)
        await fulfillment(of: [presented, updated], timeout: 3)
        XCTAssertEqual(initialContent.didAppearCount, 1)
        XCTAssertEqual(skippedContent.didAppearCount, 0)
        XCTAssertEqual(finalContent.didAppearCount, 1)
        XCTAssertNil(initialContent.parent)
        XCTAssertIdentical(finalContent.parent, sheet)
    }

    @MainActor
    func testEarlyPushThenPopCompletesWithoutChangingVisibleContent() async {
        let initialContent = MeasuredSheetContentViewController()
        let skippedContent = MeasuredSheetContentViewController()
        let sheet = NativeSheetContainerViewController(
            contentViewController: initialContent,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        let presenter = UIViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let popped = expectation(description: "Pending pop completed exactly once")
        popped.assertForOverFulfill = true
        var presentationCompleted = false

        presenter.presentAsSheet(sheet) { presentationCompleted = true }
        sheet.pushContentViewController(skippedContent)
        XCTAssertIdentical(sheet.popContentViewController {
            XCTAssertTrue(presentationCompleted)
            popped.fulfill()
        }, skippedContent)

        await fulfillment(of: [popped], timeout: 3)
        XCTAssertEqual(initialContent.didAppearCount, 1)
        XCTAssertEqual(skippedContent.didAppearCount, 0)
        XCTAssertIdentical(initialContent.parent, sheet)
        XCTAssertNil(skippedContent.parent)
    }

    @MainActor
    func testEarlyPopKeepsAppearingChildAttachedUntilPresentationCompletes() async {
        let previousContent = MeasuredSheetContentViewController()
        let initialContent = MeasuredSheetContentViewController()
        let sheet = NativeSheetContainerViewController(
            contentViewController: previousContent,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        sheet.pushContentViewController(initialContent)
        let presenter = UIViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let popped = expectation(description: "Pop after native presentation")

        presenter.presentAsSheet(sheet)
        XCTAssertTrue(sheet.rootParent.isBeingPresented)
        _ = sheet.popContentViewController { popped.fulfill() }

        XCTAssertIdentical(initialContent.parent, sheet)
        await fulfillment(of: [popped], timeout: 3)
        XCTAssertNil(initialContent.parent)
        XCTAssertIdentical(previousContent.parent, sheet)
    }

    @MainActor
    func testPopReusesContainedContentViewController() async {
        // Given
        let initialContent = NativeSheetStubContentViewController()
        let pushedContent = NativeSheetStubContentViewController()
        let sheet = NativeSheetContainerViewController(
            contentViewController: initialContent,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        sheet.pushContentViewController(pushedContent)
        XCTAssertIdentical(initialContent.parent, sheet)
        XCTAssertIdentical(pushedContent.parent, sheet)
        var completionCount = 0
        let popped = expectation(description: "Pop completed")

        // When
        let poppedContent = sheet.popContentViewController {
            completionCount += 1
            popped.fulfill()
        }
        // Content replacement completes after its fade animation, including when prepared offscreen.
        await fulfillment(of: [popped], timeout: 3)

        // Then the retained controller is restored and the popped controller is detached
        XCTAssertIdentical(poppedContent, pushedContent)
        XCTAssertNil(pushedContent.parent)
        XCTAssertIdentical(initialContent.parent, sheet)
        XCTAssertEqual(sheet.children.count, 1)
        XCTAssertEqual(completionCount, 1)
    }

    @MainActor
    func testNativeSheetIgnoresInteractiveDismissalAttempts() throws {
        // Given
        let contentViewController = NativeSheetStubContentViewController()
        let sheetViewController = NativeSheetContainerViewController(
            contentViewController: contentViewController,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        var presentedViewController: UIViewController?
        PresentationCapturingViewController { presentedViewController = $0 }.presentAsSheet(sheetViewController)
        let presentationController = try XCTUnwrap(presentedViewController?.presentationController)
        let delegate = try XCTUnwrap(presentationController.delegate)

        // When UIKit requests interactive dismissal
        let shouldDismiss = delegate.presentationControllerShouldDismiss?(presentationController)

        // Then the sheet stays open without forwarding dismissal to its content
        XCTAssertEqual(shouldDismiss, false)
        XCTAssertEqual(contentViewController.dismissalAttemptCount, 0)

        // When UIKit reports a blocked swipe or outside-tap dismissal attempt
        delegate.presentationControllerDidAttemptToDismiss?(presentationController)

        // Then the content still receives no dismissal request
        XCTAssertEqual(contentViewController.dismissalAttemptCount, 0)
    }

    @MainActor
    func testSwitchingNestedContentInvalidatesContentDetent() {
        // Given
        let contentViewController = NativeSheetStubContentViewController()
        let sheetViewController = DetentInvalidationSpyViewController(
            contentViewController: contentViewController,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        let containerView = DynamicHeightContainerView()
        contentViewController.view.addSubview(containerView)
        contentViewController.add(
            childViewController: UIViewController(),
            containerView: containerView
        )

        // When
        contentViewController.switchContentIfNecessary(
            to: UIViewController(),
            containerView: containerView
        )

        // Then
        XCTAssertEqual(sheetViewController.invalidationCount, 1)
    }

    @MainActor
    func testSelectingVerticalPaymentMethodInvalidatesContentDetent() throws {
        // Given
        let contentViewController = NativeSheetStubContentViewController()
        let sheetViewController = DetentInvalidationSpyViewController(
            contentViewController: contentViewController,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        let delegate = VerticalPaymentMethodListDelegateStub()
        let paymentMethodListViewController = VerticalPaymentMethodListViewController(
            initialSelection: nil,
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.affirm)],
            shouldShowApplePay: false,
            shouldShowLink: false,
            savedPaymentMethodAccessoryType: nil,
            overrideHeaderView: nil,
            appearance: .default,
            currency: "usd",
            amount: 1_000,
            incentive: nil,
            delegate: delegate
        )
        contentViewController.addChild(paymentMethodListViewController)
        paymentMethodListViewController.didMove(toParent: contentViewController)
        let affirmRow = try XCTUnwrap(paymentMethodListViewController.rowButtons.first)

        // When
        paymentMethodListViewController.didTap(rowButton: affirmRow, selection: affirmRow.type)

        // Then
        XCTAssertEqual(sheetViewController.invalidationCount, 1)
    }

    @MainActor
    func testNativeSheetDoesNotAddBottomSafeAreaPadding() async throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("Content-sized detents require iOS 16.") }
        // Given content whose existing bottom padding is included in its natural height
        let content = MeasuredSheetContentViewController(contentHeight: 200)
        let sheet = NativeSheetContainerViewController(
            contentViewController: content,
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )
        let presenter = UIViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let presented = expectation(description: "Content-sized native sheet presented")

        // When UIKit presents the sheet on a device with a home indicator
        presenter.presentAsSheet(sheet) { presented.fulfill() }
        await fulfillment(of: [presented], timeout: 3)
        sheet.view.layoutIfNeeded()

        // Then the content reaches the sheet's bottom, as it does in the legacy container
        XCTAssertEqual(sheet.scrollView.frame.maxY, sheet.view.bounds.maxY, accuracy: 0.5)
        let contentFrame = content.view.convert(content.view.bounds, to: sheet.view)
        XCTAssertEqual(contentFrame.maxY, sheet.view.bounds.maxY, accuracy: 0.5)
        XCTAssertEqual(sheet.scrollView.bounds.height - sheet.scrollView.adjustedContentInset.top, 200, accuracy: 0.5)
        let dismissed = expectation(description: "Native sheet dismissed")
        presenter.dismiss(animated: false) { dismissed.fulfill() }
        await fulfillment(of: [dismissed], timeout: 3)
    }

    @MainActor
    func testScrollViewAvoidsOnlyVisibleKeyboardArea() throws {
        // Given
        let sheetViewController = NativeSheetContainerViewController(
            contentViewController: NativeSheetStubContentViewController(),
            appearance: .default,
            isTestMode: true,
            didCancelNative3DS2: {}
        )

        // When
        sheetViewController.loadViewIfNeeded()

        // Then
        let keyboardAvoidanceConstraint = try XCTUnwrap(sheetViewController.view.constraints.first {
            $0.firstItem === sheetViewController.scrollView
                && $0.firstAttribute == .bottom
                && $0.secondItem === sheetViewController.view.keyboardLayoutGuide
                && $0.secondAttribute == .top
        })
        XCTAssertEqual(keyboardAvoidanceConstraint.priority, .defaultLow)
    }
}

// Captures presentation configuration without starting a UIKit transition.
private final class PresentationCapturingViewController: UIViewController {

    private let presentationHandler: (UIViewController) -> Void

    init(presentationHandler: @escaping (UIViewController) -> Void) {
        self.presentationHandler = presentationHandler
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        presentationHandler(viewControllerToPresent)
        completion?()
    }
}

private final class NativeSheetStubContentViewController: UIViewController, BottomSheetContentViewController {

    lazy var navigationBar = SheetNavigationBar(isTestMode: true, appearance: .default)
    let requiresFullScreen = false
    private(set) var dismissalAttemptCount = 0

    func didTapOrSwipeToDismiss() {
        dismissalAttemptCount += 1
    }
}

private final class DetentInvalidationSpyViewController: NativeSheetContainerViewController {

    private(set) var invalidationCount = 0

    override func invalidateContentDetent() {
        invalidationCount += 1
    }
}

private final class LinkCornerRadiusSheetViewController: NativeSheetContainerViewController {

    override var sheetCornerRadius: CGFloat? {
        LinkUI.largeCornerRadius
    }
}

private final class MeasuredSheetContentViewController: UIViewController, BottomSheetContentViewController {

    let navigationBar: SheetNavigationBar
    let requiresFullScreen = false
    private let contentHeight: CGFloat
    private(set) var didAppearCount = 0
    var onDidAppear: (() -> Void)?

    init(contentHeight: CGFloat = 200, navigationBarHeight: CGFloat = 52, appearance: PaymentSheet.Appearance = .default) {
        self.contentHeight = contentHeight
        navigationBar = FixedHeightSheetNavigationBar(height: navigationBarHeight, appearance: appearance)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.heightAnchor.constraint(equalToConstant: contentHeight).isActive = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        didAppearCount += 1
        onDidAppear?()
    }

    func didTapOrSwipeToDismiss() {}
}

private final class FixedHeightSheetNavigationBar: SheetNavigationBar {

    private let height: CGFloat

    init(height: CGFloat, appearance: PaymentSheet.Appearance) {
        self.height = height
        super.init(isTestMode: true, appearance: appearance)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: height)
    }
}

@available(iOS 16.0, *)
private final class SheetDetentResolutionContext: NSObject, UISheetPresentationControllerDetentResolutionContext {

    let containerTraitCollection = UITraitCollection()
    let maximumDetentValue: CGFloat = 1000
}

private final class VerticalPaymentMethodListDelegateStub: VerticalPaymentMethodListViewControllerDelegate {

    func willDisplayForm(_ rowButtonType: RowButtonType) -> Bool {
        return false
    }

    func didTapPaymentMethod(_ selection: RowButtonType) {}

    func didTapSavedPaymentMethodAccessoryButton() {}
}
#endif
