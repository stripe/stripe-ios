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

    func testUsesFeatureFlagRegardlessOfExperimentAssignment() {
        let flags: [Bool?] = [nil, false, true]
        let groups: [ExperimentGroup?] = [nil, .control, .treatment, .holdback, .controlTest]

        for flag in flags {
            for group in groups {
                // Given a feature flag and an assignment from the previous native-sheet experiment
                let presentation = SheetImplementationResolver(
                    elementsSession: makeSession(flag: flag, group: group)
                )

                // When the presentation decision is used more than once
                let firstDecision = presentation.usesNativeSheet
                XCTAssertEqual(presentation.usesNativeSheet, firstDecision)

                // Then the feature flag alone enables native presentation on eligible devices
                let expectedDecision = SheetImplementationResolver.isRequiredForDevice
                    || (UIDevice.current.userInterfaceIdiom == .phone && flag == true)
                XCTAssertEqual(firstDecision, expectedDecision)
            }
        }
    }

    private func makeSession(flag: Bool?, group: ExperimentGroup? = nil) -> STPElementsSession {
        return ._testValue(
            experimentsData: group.map {
                ExperimentsData(
                    arbId: "arb_native_sheet",
                    experimentAssignments: ["elements_mobile_ios_native_sheet": $0],
                    allResponseFields: [:]
                )
            },
            flags: flag.map { ["elements_mobile_ios_native_sheet_enabled": $0] } ?? [:]
        )
    }
}
