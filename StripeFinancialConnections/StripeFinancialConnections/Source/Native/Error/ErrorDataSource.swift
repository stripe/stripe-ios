//
//  ErrorDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/7/24.
//

import Foundation
@_spi(STP) import StripeCore

final class ErrorDataSource {

    let error: Error
    let referrerPane: FinancialConnectionsSessionManifest.NextPane
    let manifest: FinancialConnectionsSessionManifest
    let reduceManualEntryProminenceInErrors: Bool
    let analyticsClient: FinancialConnectionsAnalyticsClient
    let institution: FinancialConnectionsInstitution?

    init(
        error: Error,
        referrerPane: FinancialConnectionsSessionManifest.NextPane,
        manifest: FinancialConnectionsSessionManifest,
        reduceManualEntryProminenceInErrors: Bool,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        institution: FinancialConnectionsInstitution?
    ) {
        self.error = error
        self.referrerPane = referrerPane
        self.manifest = manifest
        self.reduceManualEntryProminenceInErrors = reduceManualEntryProminenceInErrors
        self.analyticsClient = analyticsClient
        self.institution = institution
    }
}
