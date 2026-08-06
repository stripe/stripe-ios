//
//  PaymentSheetLoaderFCLiteTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripePaymentSheet
import XCTest

final class PaymentSheetLoaderFCLiteTests: XCTestCase {
    func testShouldPreferFCLiteWhenElementsSessionFlagEnabled() {
        let elementsSession = STPElementsSession._testValue(
            flags: ["elements_prefer_fc_lite": true]
        )

        XCTAssertTrue(PaymentSheetLoader.shouldPreferFCLite(elementsSession: elementsSession))
    }

    func testShouldPreferFCLiteWhenExperimentAssignmentIsTreatment() {
        let experimentsData = ExperimentsData(
            arbId: "test_arb",
            experimentAssignments: [ConnectionsFCLiteVsNative.experimentName: .treatment],
            allResponseFields: [:]
        )
        let elementsSession = STPElementsSession._testValue(
            experimentsData: experimentsData
        )

        XCTAssertTrue(PaymentSheetLoader.shouldPreferFCLite(elementsSession: elementsSession))
    }

    func testShouldNotPreferFCLiteWhenFlagDisabledAndExperimentNotInTreatment() {
        let experimentsData = ExperimentsData(
            arbId: "test_arb",
            experimentAssignments: [ConnectionsFCLiteVsNative.experimentName: .control],
            allResponseFields: [:]
        )
        let elementsSession = STPElementsSession._testValue(
            experimentsData: experimentsData
        )

        XCTAssertFalse(PaymentSheetLoader.shouldPreferFCLite(elementsSession: elementsSession))
    }
}
