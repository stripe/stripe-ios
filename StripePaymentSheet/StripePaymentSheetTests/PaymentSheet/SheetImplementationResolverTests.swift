//
//  SheetImplementationResolverTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 9/30/26.
//

@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) import StripeUICore
import UIKit
import XCTest

@MainActor
final class SheetImplementationResolverTests: XCTestCase {

    override func tearDown() {
        PaymentSheet.NativeSheetFeatureFlags.nativeSheetEnabledOverride = nil
        super.tearDown()
    }

    func testPlaygroundOverrideForcesDecisionAndIsCapturedPerFlow() {
        let cases: [(override: Bool, flag: Bool)] = [
            (true, false),
            (false, true),
        ]

        for testCase in cases {
            // Given an override that contradicts the server-provided feature flag
            PaymentSheet.NativeSheetFeatureFlags.nativeSheetEnabledOverride = testCase.override
            let presentation = SheetImplementationResolver(
                elementsSession: makeSession(flag: testCase.flag)
            )

            // When the global override changes after this flow captures its decision
            PaymentSheet.NativeSheetFeatureFlags.nativeSheetEnabledOverride = !testCase.override

            // Then this flow retains the original override
            let expectedDecision = SheetImplementationResolver.isRequiredForDevice
                || (UIDevice.current.userInterfaceIdiom == .phone && testCase.override)
            XCTAssertEqual(presentation.usesNativeSheet, expectedDecision)
        }
    }

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
    #endif

    func testLegacyContainerKeepsKeyboardAndPresentationTransitionHandling() {
        let sheet = BottomSheetViewController(
            contentViewController: StubBottomSheetContentViewController(),
            appearance: .default,
            isTestMode: true,
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
            paymentMethodOrientation: .vertical
        )
    }
}
