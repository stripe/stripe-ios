//
//  SheetImplementationResolverTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 9/30/26.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
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

    func testRequiresEnabledFlagAndTreatmentAssignment() {
        let flags: [Bool?] = [nil, false, true]
        let groups: [ExperimentGroup?] = [nil, .control, .treatment, .holdback, .controlTest]

        for flag in flags {
            for group in groups {
                // Given all combinations of the kill switch and experiment assignment
                let analyticsClient = MockAnalyticsClientV2()
                let presentation = SheetImplementationResolver(
                    elementsSession: makeSession(flag: flag, group: group),
                    analyticsHelper: ._testValue(analyticsClientV2: analyticsClient),
                    integrationShape: "flowcontroller"
                )
                XCTAssertTrue(analyticsClient.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName).isEmpty)

                // When the presentation decision is used more than once
                let firstDecision = presentation.usesNativeSheet
                XCTAssertEqual(presentation.usesNativeSheet, firstDecision)

                // Then only enabled treatment uses native presentation, and eligible exposure is logged once
                let isEligibleDevice = UIDevice.current.userInterfaceIdiom == .phone
                XCTAssertEqual(firstDecision, isEligibleDevice && flag == true && group == .treatment)
                let exposures = analyticsClient.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName)
                XCTAssertEqual(exposures.count, isEligibleDevice && flag == true && group != nil ? 1 : 0)
                if let exposure = exposures.first {
                    XCTAssertEqual(exposure["experiment_retrieved"] as? String, NativeSheetExperiment.experimentName)
                    XCTAssertEqual(exposure["assignment_group"] as? String, group?.rawValue)
                    XCTAssertEqual(exposure["arb_id"] as? String, "arb_native_sheet")
                    XCTAssertEqual(exposure["dimensions-integration_shape"] as? String, "flowcontroller")
                }
            }
        }
    }

    func testPlaygroundOverrideForcesDecisionAndIsCapturedPerFlow() {
        let cases: [(override: Bool, flag: Bool, group: ExperimentGroup)] = [
            (true, false, .control),
            (false, true, .treatment),
        ]

        for testCase in cases {
            // Given an override that contradicts the server-provided rollout decision
            PaymentSheet.NativeSheetFeatureFlags.nativeSheetEnabledOverride = testCase.override
            let analyticsClient = MockAnalyticsClientV2()
            let presentation = SheetImplementationResolver(
                elementsSession: makeSession(flag: testCase.flag, group: testCase.group),
                analyticsHelper: ._testValue(analyticsClientV2: analyticsClient),
                integrationShape: "flowcontroller"
            )

            // When the global override changes after this flow captures its decision
            PaymentSheet.NativeSheetFeatureFlags.nativeSheetEnabledOverride = !testCase.override

            // Then this flow retains the original override without logging an experiment exposure
            let expectedDecision = SheetImplementationResolver.isRequiredForDevice
                || (UIDevice.current.userInterfaceIdiom == .phone && testCase.override)
            XCTAssertEqual(presentation.usesNativeSheet, expectedDecision)
            XCTAssertTrue(
                analyticsClient.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName).isEmpty
            )
        }
    }

    func testEmbeddedKeepsInitialDecisionWhenElementsSessionChanges() async {
        await AddressSpecProvider.shared.loadAddressSpecs()
        let analyticsClient = MockAnalyticsClientV2()
        let element = EmbeddedPaymentElement(
            configuration: .init(),
            loadResult: makeLoadResult(flag: true, group: .treatment),
            analyticsHelper: ._testValue(analyticsClientV2: analyticsClient)
        )
        let initialPresentation = element.nativeSheetPresentation

        // When an update replaces the Elements Session before the first sheet is opened
        element.loadResult = makeLoadResult(flag: false, group: .control)
        XCTAssertTrue(analyticsClient.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName).isEmpty)
        let sheet = element.bottomSheetController(with: StubBottomSheetContentViewController())

        // Then the original assignment is retained by the owner and its container
        XCTAssertIdentical(element.nativeSheetPresentation, initialPresentation)
        #if os(visionOS)
        XCTAssertTrue(sheet is BottomSheetViewController)
        #else
        XCTAssertEqual(sheet is NativeSheetContainerViewController, UIDevice.current.userInterfaceIdiom == .phone)
        #endif
    }

    func testNewFlowControllerDoesNotShareDecisionWhenConfigurationIsReused() async {
        await AddressSpecProvider.shared.loadAddressSpecs()
        let previousFlowController = PaymentSheet.FlowController(
            configuration: .init(),
            loadResult: makeLoadResult(flag: true, group: .treatment),
            analyticsHelper: ._testValue()
        )
        let analyticsClient = MockAnalyticsClientV2()

        // When a merchant reuses a previous FlowController's configuration for a new flow
        let flowController = PaymentSheet.FlowController(
            configuration: previousFlowController.configuration,
            loadResult: makeLoadResult(flag: true, group: .control),
            analyticsHelper: ._testValue(analyticsClientV2: analyticsClient)
        )

        // Then the new flow captures its own assignment without logging an early exposure
        XCTAssertFalse(flowController.nativeSheetPresentation === previousFlowController.nativeSheetPresentation)
        XCTAssertTrue(analyticsClient.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName).isEmpty)
        let sheet = PaymentSheet.FlowController.makePaymentSheetContainerViewController(
            flowController.viewController,
            configuration: flowController.configuration,
            nativeSheetPresentation: flowController.nativeSheetPresentation
        )
        XCTAssertTrue(sheet is BottomSheetViewController)
    }

    func testCompletePaymentSheetDoesNotInheritFlowControllerRollout() async {
        await AddressSpecProvider.shared.loadAddressSpecs()
        let analyticsClient = MockAnalyticsClientV2()
        // Given a FlowController with a treatment assignment
        let flowController = PaymentSheet.FlowController(
            configuration: .init(),
            loadResult: makeLoadResult(flag: true, group: .treatment),
            analyticsHelper: ._testValue(analyticsClientV2: analyticsClient)
        )

        // When complete PaymentSheet reuses its configuration
        let paymentSheet = PaymentSheet(
            intentConfiguration: .init(mode: .payment(amount: 1000, currency: "usd")) { _, _ in "" },
            configuration: flowController.configuration
        )

        // Then complete PaymentSheet stays outside the rollout and does not expose the other flow
        XCTAssertFalse(paymentSheet.bottomSheetViewController is NativeSheetContainerViewController)
        XCTAssertTrue(analyticsClient.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName).isEmpty)
    }

    #if !os(visionOS)
    func testNativeLinkInheritsPresentationDecision() async {
        await AddressSpecProvider.shared.loadAddressSpecs()
        for group in [ExperimentGroup.control, .treatment] {
            let analyticsClient = MockAnalyticsClientV2()
            let analyticsHelper = PaymentSheetAnalyticsHelper._testValue(analyticsClientV2: analyticsClient)
            let loadResult = makeLoadResult(flag: true, group: group)
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

            // Then the Link container uses the same assignment and shares its one exposure
            XCTAssertEqual(
                sheet.sheetContainer is NativeSheetContainerViewController,
                UIDevice.current.userInterfaceIdiom == .phone && group == .treatment
            )
            _ = flowController.nativeSheetPresentation.usesNativeSheet
            let exposures = analyticsClient.loggedAnalyticPayloads(withEventName: PaymentSheetAnalyticsHelper.eventName)
            XCTAssertEqual(exposures.count, UIDevice.current.userInterfaceIdiom == .phone ? 1 : 0)
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

    private func makeSession(flag: Bool?, group: ExperimentGroup?) -> STPElementsSession {
        return ._testValue(
            experimentsData: group.map {
                ExperimentsData(
                    arbId: "arb_native_sheet",
                    experimentAssignments: [NativeSheetExperiment.experimentName: $0],
                    allResponseFields: [:]
                )
            },
            flags: flag.map { ["elements_mobile_ios_native_sheet_enabled": $0] } ?? [:]
        )
    }

    private func makeLoadResult(flag: Bool?, group: ExperimentGroup?) -> PaymentSheetLoader.LoadResult {
        let intentConfiguration = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "usd")) { _, _ in "" }
        return .init(
            intent: .deferredIntent(intentConfig: intentConfiguration),
            elementsSession: makeSession(flag: flag, group: group),
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: nil,
            paymentMethodOrientation: .vertical
        )
    }
}
