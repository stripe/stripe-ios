//
//  FlowRouterTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Mat Schmid on 2024-07-24.
//

@_spi(STP) import StripeCoreTestUtils
@testable import StripeFinancialConnections
import XCTest

class FlowRouterTests: XCTestCase {
    private static let exmapleAppNativeOverrideKey = "FINANCIAL_CONNECTIONS_EXAMPLE_APP_ENABLE_NATIVE"

    private enum Experience {
        case financialConnections
        case instantDebits
    }

    var flowRouter: FlowRouter!
    let mockAnalyticsClient = FinancialConnectionsAnalyticsClient(analyticsClient: MockAnalyticsClientV2())

    override func tearDown() {
        super.tearDown()
        flowRouter = nil
        UserDefaults.standard.removeObject(forKey: Self.exmapleAppNativeOverrideKey)
    }

    // MARK: Financial Connections

    func testFinancialConnectionsKillswitchActive() {
        flowRouter = FlowRouter(
            synchronizePayload: synchronizePayload(
                experience: .financialConnections,
                killswitchActive: true,
                nativeExperimentEnabled: true
            ),
            analyticsClient: mockAnalyticsClient
        )

        XCTAssertEqual(flowRouter.flow, .webFinancialConnections)
    }

    func testFinancialConnectionsKillswitchNotActive() {
        flowRouter = FlowRouter(
            synchronizePayload: synchronizePayload(
                experience: .financialConnections,
                killswitchActive: false,
                nativeExperimentEnabled: true
            ),
            analyticsClient: mockAnalyticsClient
        )

        XCTAssertEqual(flowRouter.flow, .nativeFinancialConnections)
    }

    func testFinancialConnectionsNativeExperimentDisabled() {
        flowRouter = FlowRouter(
            synchronizePayload: synchronizePayload(
                experience: .financialConnections,
                killswitchActive: false,
                nativeExperimentEnabled: false
            ),
            analyticsClient: mockAnalyticsClient
        )

        XCTAssertEqual(flowRouter.flow, .webFinancialConnections)
    }

    func testFinancialConnectionsNativeSdkOverrideTrue() {
        UserDefaults.standard.set(true, forKey: Self.exmapleAppNativeOverrideKey)

        flowRouter = FlowRouter(
            synchronizePayload: synchronizePayload(
                experience: .financialConnections,
                killswitchActive: false,
                nativeExperimentEnabled: false
            ),
            analyticsClient: mockAnalyticsClient
        )

        XCTAssertEqual(flowRouter.flow, .nativeFinancialConnections)
    }

    func testFinancialConnectionsNativeSdkOverrideFalse() {
        UserDefaults.standard.set(false, forKey: Self.exmapleAppNativeOverrideKey)

        flowRouter = FlowRouter(
            synchronizePayload: synchronizePayload(
                experience: .financialConnections,
                killswitchActive: false,
                nativeExperimentEnabled: false
            ),
            analyticsClient: mockAnalyticsClient
        )

        XCTAssertEqual(flowRouter.flow, .webFinancialConnections)
    }

    // MARK: Instant Debits

    func testInstantDebitsKillswitchActive() {
        flowRouter = FlowRouter(
            synchronizePayload: synchronizePayload(
                experience: .instantDebits,
                killswitchActive: true,
                nativeExperimentEnabled: true
            ),
            analyticsClient: mockAnalyticsClient
        )

        XCTAssertEqual(flowRouter.flow, .webInstantDebits)
    }

    func testInstantDebitsKillswitchNotActive() {
        flowRouter = FlowRouter(
            synchronizePayload: synchronizePayload(
                experience: .instantDebits,
                killswitchActive: false,
                nativeExperimentEnabled: true
            ),
            analyticsClient: mockAnalyticsClient
        )

        XCTAssertEqual(flowRouter.flow, .nativeInstantDebits)
    }

    func testInstantDebitsNativeSdkOverrideTrue() {
        UserDefaults.standard.set(true, forKey: Self.exmapleAppNativeOverrideKey)

        flowRouter = FlowRouter(
            synchronizePayload: synchronizePayload(
                experience: .instantDebits,
                killswitchActive: false,
                nativeExperimentEnabled: false
            ),
            analyticsClient: mockAnalyticsClient
        )

        XCTAssertEqual(flowRouter.flow, .nativeInstantDebits)
    }

    func testInstantDebitsNativeSdkOverrideFalse() {
        UserDefaults.standard.set(false, forKey: Self.exmapleAppNativeOverrideKey)

        flowRouter = FlowRouter(
            synchronizePayload: synchronizePayload(
                experience: .instantDebits,
                killswitchActive: false,
                nativeExperimentEnabled: false
            ),
            analyticsClient: mockAnalyticsClient
        )

        XCTAssertEqual(flowRouter.flow, .webInstantDebits)
    }

    // MARK: Helpers

    private func synchronizePayload(experience: Experience, killswitchActive: Bool, nativeExperimentEnabled: Bool) -> FinancialConnectionsSynchronize {
        FinancialConnectionsSynchronize(
            manifest: FinancialConnectionsSessionManifest(
                allowManualEntry: false,
                consentRequired: false,
                customManualEntryHandling: false,
                disableLinkMoreAccounts: false,
                experimentAssignments: ["connections_mobile_native": nativeExperimentEnabled ? "treatment" : ""],
                features: ["bank_connections_mobile_native_version_killswitch": killswitchActive],
                instantVerificationDisabled: false,
                institutionSearchDisabled: false,
                livemode: false,
                manualEntryMode: .automatic,
                manualEntryUsesMicrodeposits: false,
                nextPane: .consent,
                permissions: [],
                product: experience == .instantDebits ? "instant_debits" : "connections",
                singleAccount: true
            ),
            text: nil,
            visual: .init(
                reducedBranding: false,
                merchantLogo: [],
                reduceManualEntryProminenceInErrors: false
            )
        )
    }
}
