//
//  ExperimentHelper.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 12/22/22.
//

import Foundation

/// Abstracts experimentation logic for a specific experiment.
final class ExperimentHelper {

    private let experimentName: String
    private let manifest: FinancialConnectionsSessionManifest
    private let analyticsClient: FinancialConnectionsAnalyticsClient
    private var didLogExposure = false

    private var isExperimentValid: Bool {
        return experimentVariant != nil && manifest.assignmentEventId != nil && manifest.accountholderToken != nil
    }
    private var experimentVariant: String? {
        return manifest.experimentAssignments?[experimentName]
    }

    init(
        experimentName: String,
        manifest: FinancialConnectionsSessionManifest,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.experimentName = experimentName
        self.manifest = manifest
        self.analyticsClient = analyticsClient
    }

    // Helper where we assume that we have two groups: "control" and "treatment."
    // If user is in "treatment" group, we return `true`.
    func isEnabled(logExposure: Bool) -> Bool {
        guard isExperimentValid else {
            return false
        }
        if logExposure {
            logExposureIfNeeded()
        }
        return experimentVariant == "treatment"
    }

    private func logExposureIfNeeded() {
        guard isExperimentValid else {
            return
        }
        guard let assignmentEventId = manifest.assignmentEventId else {
            assertionFailure("`isExperimentValid` should ensure `assignmentEventId` is non-null")
            return
        }
        guard let accountholderToken = manifest.accountholderToken else {
            assertionFailure("`isExperimentValid` should ensure `accountholderToken` is non-null")
            return
        }

        if !didLogExposure {
            didLogExposure = true
            analyticsClient.logExposure(
                experimentName: experimentName,
                assignmentEventId: assignmentEventId,
                accountholderToken: accountholderToken
            )
        }
    }
}
