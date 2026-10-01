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
}
