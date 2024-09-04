//
//  FlowRouter.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 11/1/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

class FlowRouter {

    enum Flow: String {
        case webInstantDebits = "web_instant_debits"
        case nativeInstantDebits = "native_instant_debits"
        case webFinancialConnections = "web_financial_connections"
        case nativeFinancialConnections = "native_financial_connections"
    }

    private enum ExampleAppOverride: Equatable {
        case native
        case web
        case none

        var shouldUseNativeFlow: Bool {
            self == .native
        }
    }

    private let synchronizePayload: FinancialConnectionsSynchronize
    private let analyticsClient: FinancialConnectionsAnalyticsClient

    // MARK: - Init

    init(
        synchronizePayload: FinancialConnectionsSynchronize,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.synchronizePayload = synchronizePayload
        self.analyticsClient = analyticsClient
    }

    // MARK: - Public

    var flow: Flow {
        if synchronizePayload.manifest.isProductInstantDebits {
            return shouldUseNativeInstantDebits ? .nativeInstantDebits : .webInstantDebits
        } else {
            logExposureIfNeeded()
            return shouldUseNativeFinancialConnections ? .nativeFinancialConnections : .webFinancialConnections
        }
    }

    var killswitchActive: Bool {
        // If the manifest is missing features map, fallback to webview.
        guard let features = synchronizePayload.manifest.features else { return true }

        // If native version killswitch feature is missing, fallback to webview.
        guard let killswitchValue = features[Constants.killswitchFeature] else { return true }

        return killswitchValue
    }

    // MARK: - Private

    /// Returns `.native` if the FC example app has the native SDK selected, `.web` if the web SDK is selected, and `.none` otherwise.
    private var exampleAppSdkOverride: ExampleAppOverride {
        if let nativeOverride = UserDefaults.standard.value(
            forKey: "FINANCIAL_CONNECTIONS_EXAMPLE_APP_ENABLE_NATIVE"
        ) as? Bool {
            return nativeOverride ? .native : .web
        }
        return .none
    }

    private var shouldUseNativeFinancialConnections: Bool {
        // Override all other conditions if the example app has native or web selected.
        guard case .none = exampleAppSdkOverride else {
            return exampleAppSdkOverride.shouldUseNativeFlow
        }

        // if this version is killswitched by server, fallback to webview.
        if killswitchActive { return false }

        // If native experiment is missing, fallback to webview.
        guard let experimentVariant = experimentVariant else { return false }

        return experimentVariant == Constants.nativeExperimentTreatment
    }

    private var shouldUseNativeInstantDebits: Bool {
        // Override all other conditions if the example app has native or web selected.
        guard case .none = exampleAppSdkOverride else {
            return exampleAppSdkOverride.shouldUseNativeFlow
        }

        return !killswitchActive
    }

    private var experimentVariant: String? {
        return synchronizePayload.manifest.experimentAssignments?[Constants.nativeExperiment]
    }

    func logExposureIfNeeded() {

        // if this version is killswitched by server, don't log exposure.
        if killswitchActive { return }

        // If native experiment is missing, don't log exposure.
        if experimentVariant == nil { return }

        // If assignmentIdIsMissing, don't log exposure.
        guard let assignmentEventId = synchronizePayload.manifest.assignmentEventId else { return }

        // If account holder is unknown, don't log exposure.
        guard let accountHolder = synchronizePayload.manifest.accountholderToken else { return }

        analyticsClient.logExposure(
            experimentName: Constants.nativeExperiment,
            assignmentEventId: assignmentEventId,
            accountholderToken: accountHolder
        )
    }
}

// MARK: - Constants

private extension FlowRouter {
    enum Constants {
        static let killswitchFeature = "bank_connections_mobile_native_version_killswitch"
        static let nativeExperiment = "connections_mobile_native"
        static let nativeExperimentTreatment = "treatment"
    }
}
