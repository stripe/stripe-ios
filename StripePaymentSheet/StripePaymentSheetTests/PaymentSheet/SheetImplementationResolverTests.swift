//
//  SheetImplementationResolverTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 9/30/26.
//

@_spi(InternalOnlyAPI) @_spi(CryptoOnrampAlpha) @testable import StripePaymentSheet
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit
import XCTest

@MainActor
final class SheetImplementationResolverTests: XCTestCase {

    func testEmbeddedKeepsInitialDecisionWhenElementsSessionChanges() async {
        await AddressSpecProvider.shared.loadAddressSpecs()
        let element = EmbeddedPaymentElement(
            configuration: .init(),
            loadResult: makeLoadResult(flag: true),
            analyticsHelper: ._testValue()
        )
        let initialPresentation = element.nativeSheetPresentation

        // When an update replaces the Elements Session before the first sheet is opened
        element.loadResult = makeLoadResult(flag: false)
        let sheet = element.bottomSheetController(with: StubBottomSheetContentViewController())

        // Then the original feature flag is retained by the owner and its container
        XCTAssertIdentical(element.nativeSheetPresentation, initialPresentation)
        #if os(visionOS)
        XCTAssertTrue(sheet is BottomSheetViewController)
        #else
        XCTAssertEqual(
            sheet is NativeSheetContainerViewController,
            SheetImplementationResolver.isRequiredForDevice || UIDevice.current.userInterfaceIdiom == .phone
        )
        #endif
    }

    func testNewFlowControllerDoesNotShareDecisionWhenConfigurationIsReused() async {
        await AddressSpecProvider.shared.loadAddressSpecs()
        let previousFlowController = PaymentSheet.FlowController(
            configuration: .init(),
            loadResult: makeLoadResult(flag: true),
            analyticsHelper: ._testValue()
        )

        // When a merchant reuses a previous FlowController's configuration for a new flow
        let flowController = PaymentSheet.FlowController(
            configuration: previousFlowController.configuration,
            loadResult: makeLoadResult(flag: false),
            analyticsHelper: ._testValue()
        )

        // Then the new flow captures its own feature flag
        XCTAssertFalse(flowController.nativeSheetPresentation === previousFlowController.nativeSheetPresentation)
        let sheet = PaymentSheet.FlowController.makePaymentSheetContainerViewController(
            flowController.viewController,
            configuration: flowController.configuration,
            nativeSheetPresentation: flowController.nativeSheetPresentation
        )
        XCTAssertEqual(sheet is NativeSheetContainerViewController, SheetImplementationResolver.isRequiredForDevice)
    }

    func testCompletePaymentSheetDoesNotInheritFlowControllerFeatureFlag() async {
        await AddressSpecProvider.shared.loadAddressSpecs()
        // Given a FlowController with the native-sheet feature flag enabled
        let flowController = PaymentSheet.FlowController(
            configuration: .init(),
            loadResult: makeLoadResult(flag: true),
            analyticsHelper: ._testValue()
        )

        // When complete PaymentSheet reuses its configuration
        let paymentSheet = PaymentSheet(
            intentConfiguration: .init(mode: .payment(amount: 1000, currency: "usd")) { _, _ in "" },
            configuration: flowController.configuration
        )

        // Then complete PaymentSheet uses native presentation only when required by the device
        XCTAssertEqual(
            paymentSheet.bottomSheetViewController is NativeSheetContainerViewController,
            SheetImplementationResolver.isRequiredForDevice
        )
    }

    #if !os(visionOS)
    func testNativeLinkInheritsPresentationDecision() async {
        await AddressSpecProvider.shared.loadAddressSpecs()
        for flag in [false, true] {
            let analyticsHelper = PaymentSheetAnalyticsHelper._testValue()
            let loadResult = makeLoadResult(flag: flag)
            let flowController = PaymentSheet.FlowController(
                configuration: .init(),
                loadResult: loadResult,
                analyticsHelper: analyticsHelper
            )

            // When native Link is opened with its owning flow's presentation state
            let sheet = PayWithLinkViewController(
                intent: loadResult.intent,
                linkAccount: nil,
                elementsSession: loadResult.elementsSession,
                configuration: flowController.configuration,
                nativeSheetPresentation: flowController.nativeSheetPresentation,
                analyticsHelper: analyticsHelper
            )

            // Then the Link container uses the same feature flag
            XCTAssertEqual(
                sheet.sheetContainer is NativeSheetContainerViewController,
                SheetImplementationResolver.isRequiredForDevice || (UIDevice.current.userInterfaceIdiom == .phone && flag)
            )
        }
    }

    func testNativeLinkFromCompletePaymentSheetMatchesPaymentSheetContainer() async throws {
        await AddressSpecProvider.shared.loadAddressSpecs()
        let previousOverride = PaymentSheet.NativeSheetFeatureFlags.nativeSheetEnabledOverride
        defer { PaymentSheet.NativeSheetFeatureFlags.nativeSheetEnabledOverride = previousOverride }
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        for override in [false, true] {
            // Given a complete PaymentSheet whose container was created with the playground override
            PaymentSheet.NativeSheetFeatureFlags.nativeSheetEnabledOverride = override
            let paymentSheet = PaymentSheet(
                intentConfiguration: .init(mode: .payment(amount: 1000, currency: "usd")) { _, _ in "" },
                configuration: .init()
            )
            let paymentSheetUsesNativeSheet = paymentSheet.bottomSheetViewController is NativeSheetContainerViewController
            XCTAssertEqual(
                paymentSheetUsesNativeSheet,
                SheetImplementationResolver.isRequiredForDevice || (UIDevice.current.userInterfaceIdiom == .phone && override)
            )
            // ...and the override changes before Link is opened
            PaymentSheet.NativeSheetFeatureFlags.nativeSheetEnabledOverride = !override
            let presenter = UIViewController()
            let window = UIWindow(windowScene: scene)
            window.frame = scene.coordinateSpace.bounds
            window.rootViewController = presenter
            window.makeKeyAndVisible()

            // When PaymentSheet opens native Link
            let loadResult = makeLoadResult(flag: nil)
            paymentSheet.presentPayWithNativeLinkController(
                from: presenter,
                intent: loadResult.intent,
                elementsSession: loadResult.elementsSession,
                shouldOfferApplePay: false,
                shouldFinishOnClose: false
            )

            // Then Link uses the same sheet implementation as PaymentSheet
            let linkSheet = try XCTUnwrap(presenter.presentedViewController?.bottomSheetController)
            XCTAssertEqual(linkSheet is LinkNativeSheetContainerViewController, paymentSheetUsesNativeSheet)
            XCTAssertEqual(linkSheet is LinkBottomSheetViewController, !paymentSheetUsesNativeSheet)
            presenter.dismiss(animated: false)
            window.isHidden = true
        }
    }

    func testLinkControllerSheetsFollowLocalOverrideAndElementsSessionFlag() async {
        await AddressSpecProvider.shared.loadAddressSpecs()
        let previousOverride = PaymentSheet.NativeSheetFeatureFlags.nativeSheetEnabledOverride
        defer { PaymentSheet.NativeSheetFeatureFlags.nativeSheetEnabledOverride = previousOverride }
        let cases: [(override: Bool?, flag: Bool, expectsNativeSheet: Bool)] = [
            (nil, false, false),
            (nil, true, true),
            (true, false, true),
            (false, true, false),
        ]
        for testCase in cases {
            // Given a LinkController created with the local override and Elements Session flag
            PaymentSheet.NativeSheetFeatureFlags.nativeSheetEnabledOverride = testCase.override
            let loadResult = makeLoadResult(flag: testCase.flag)
            let linkController = LinkController(
                mode: .payment,
                elementsSession: loadResult.elementsSession,
                intent: loadResult.intent,
                paymentElementConfiguration: PaymentSheet.Configuration(),
                linkBrand: .link,
                appearance: nil,
                configuration: nil,
                analyticsHelper: ._testValue(),
                requestSurface: .default
            )
            // ...and the override changes after creation
            PaymentSheet.NativeSheetFeatureFlags.nativeSheetEnabledOverride = !(testCase.override ?? testCase.flag)

            // When the controller's sheets are created
            let kycSheet = VerifyKYCViewController(
                info: StubKYCInfo(),
                appearance: .init(),
                nativeSheetPresentation: linkController.nativeSheetPresentation
            ).sheetContainer
            let htmlSheet = HTMLConfirmationViewController(
                heading: "Confirm",
                html: "<p>Confirm your information.</p>",
                confirmationButtonTitle: "Confirm",
                appearance: .init(),
                brand: .link,
                nativeSheetPresentation: linkController.nativeSheetPresentation
            ).sheetContainer

            // Then they use the decision captured when the controller was created
            let expectsNativeSheet = SheetImplementationResolver.isRequiredForDevice
                || (UIDevice.current.userInterfaceIdiom == .phone && testCase.expectsNativeSheet)
            XCTAssertEqual(linkController.nativeSheetPresentation.usesNativeSheet, expectsNativeSheet)
            XCTAssertEqual(kycSheet is LinkNativeSheetContainerViewController, expectsNativeSheet)
            XCTAssertEqual(htmlSheet is LinkNativeSheetContainerViewController, expectsNativeSheet)
        }
    }
    #endif

    func testLegacyContainerKeepsKeyboardAndPresentationTransitionHandling() {
        let sheet = BottomSheetViewController(
            contentViewController: StubBottomSheetContentViewController(),
            appearance: .default,
            didCancelNative3DS2: {}
        )
        sheet.loadViewIfNeeded()
        XCTAssertTrue(sheet.view.constraints.contains {
            $0.firstItem === sheet.scrollView && $0.firstAttribute == .bottom
                && $0.secondItem === sheet.view && $0.secondAttribute == .bottom
        })
        var presentationFinished = false
        sheet.completeBottomSheetPresentationTransition = { _ in presentationFinished = true }

        sheet.setViewControllers([StubBottomSheetContentViewController()])

        XCTAssertTrue(presentationFinished)
    }

    private func makeSession(flag: Bool?) -> STPElementsSession {
        return ._testValue(
            flags: flag.map { ["elements_mobile_ios_native_sheet_enabled": $0] } ?? [:]
        )
    }

    private func makeLoadResult(flag: Bool?) -> PaymentSheetLoader.LoadResult {
        let intentConfiguration = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "usd")) { _, _ in "" }
        return .init(
            intent: .deferredIntent(intentConfig: intentConfiguration),
            elementsSession: makeSession(flag: flag),
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: nil,
            paymentMethodOrientation: .vertical,
            customerProvider: CustomerProvider(customer: nil)
        )
    }
}
