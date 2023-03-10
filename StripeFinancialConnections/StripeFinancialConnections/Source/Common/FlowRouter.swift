//
//  FlowRouter.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 11/1/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

class FlowRouter {

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

    // MARK: - Private

    private var killswitchActive: Bool {
        // If the manifest is missing features map, fallback to webview.
        guard let features = synchronizePayload.manifest.features else { return true }

        // If native version killswitch feature is missing, fallback to webview.
        guard let killswitchValue = features[Constants.killswitchFeature] else { return true }

        return killswitchValue
    }

    private var experimentVariant: String? {
        return synchronizePayload.manifest.experimentAssignments?[Constants.nativeExperiment]
    }

    // MARK: - Public

    var shouldUseNative: Bool {
        if let isNativeEnabled = UserDefaults.standard.value(
            forKey: "FINANCIAL_CONNECTIONS_EXAMPLE_APP_ENABLE_NATIVE"
        ) as? Bool {
            return isNativeEnabled
        }

        // if this version is killswitched by server, fallback to webview.
        if killswitchActive { return false }

        // If native experiment is missing, fallback to webview.
        guard let experimentVariant = experimentVariant else { return false }

        return experimentVariant == Constants.nativeExperimentTreatment
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
