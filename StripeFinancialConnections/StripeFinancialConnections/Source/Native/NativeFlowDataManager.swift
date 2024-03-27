//
//  NativeFlowDataManager.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/7/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol NativeFlowDataManager: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get set }
    var reducedBranding: Bool { get }
    var merchantLogo: [String]? { get }
    var returnURL: String? { get }
    var consentPaneModel: FinancialConnectionsConsent? { get }
    var apiClient: FinancialConnectionsAPIClient { get }
    var clientSecret: String { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    var reduceManualEntryProminenceInErrors: Bool { get }

    var institution: FinancialConnectionsInstitution? { get set }
    var authSession: FinancialConnectionsAuthSession? { get set }
    var linkedAccounts: [FinancialConnectionsPartnerAccount]? { get set }
    var terminalError: Error? { get set }
    var errorPaneError: Error? { get set }
    var errorPaneReferrerPane: FinancialConnectionsSessionManifest.NextPane? { get set }
    var paymentAccountResource: FinancialConnectionsPaymentAccountResource? { get set }
    var accountNumberLast4: String? { get set }
    var consumerSession: ConsumerSessionData? { get set }
    var saveToLinkWithStripeSucceeded: Bool? { get set }
    var lastPaneLaunched: FinancialConnectionsSessionManifest.NextPane? { get set }
    var customSuccessPaneMessage: String? { get set }

    func resetState(withNewManifest newManifest: FinancialConnectionsSessionManifest)
    func completeFinancialConnectionsSession(terminalError: String?) -> Future<StripeAPI.FinancialConnectionsSession>
}

class NativeFlowAPIDataManager: NativeFlowDataManager {

    private lazy var consentCombinedLogoExperiment: ExperimentHelper = {
        return ExperimentHelper(
            experimentName: "connections_consent_combined_logo",
            manifest: manifest,
            analyticsClient: analyticsClient
        )
    }()
    var manifest: FinancialConnectionsSessionManifest {
        didSet {
            didUpdateManifest()
        }
    }
    // don't expose `visualUpdate` because we don't want anyone to directly
    // access `visualUpdate.merchantLogo`; we have custom logic for `merchantLogo`
    private let visualUpdate: FinancialConnectionsSynchronize.VisualUpdate
    var reducedBranding: Bool {
        return visualUpdate.reducedBranding
    }
    var merchantLogo: [String]? {
        if consentCombinedLogoExperiment.isEnabled(logExposure: true) {
            let merchantLogo = visualUpdate.merchantLogo
            if merchantLogo.isEmpty || merchantLogo.count == 2 || merchantLogo.count == 3 {
                // show merchant logo inside of consent pane
                return visualUpdate.merchantLogo
            } else {
                // if `merchantLogo.count > 3`, that is an invalid case
                //
                // we want to log experiment exposure regardless because
                // if experiment is not working fine (ex. returns 1 or 4 logos)
                // then the "cost" of those bugs should show up in the `treatment` data
                return nil
            }
        } else {
            // show the "control" experience of showing logo in the nav bar
            return nil
        }
    }
    var reduceManualEntryProminenceInErrors: Bool {
        return visualUpdate.reduceManualEntryProminenceInErrors
    }
    let returnURL: String?
    let consentPaneModel: FinancialConnectionsConsent?
    let apiClient: FinancialConnectionsAPIClient
    let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient

    var institution: FinancialConnectionsInstitution?
    var authSession: FinancialConnectionsAuthSession?
    var linkedAccounts: [FinancialConnectionsPartnerAccount]?
    var terminalError: Error?
    var errorPaneError: Error?
    var errorPaneReferrerPane: FinancialConnectionsSessionManifest.NextPane?
    var paymentAccountResource: FinancialConnectionsPaymentAccountResource?
    var accountNumberLast4: String?
    var consumerSession: ConsumerSessionData?
    var saveToLinkWithStripeSucceeded: Bool?
    var lastPaneLaunched: FinancialConnectionsSessionManifest.NextPane?
    var customSuccessPaneMessage: String?

    init(
        manifest: FinancialConnectionsSessionManifest,
        visualUpdate: FinancialConnectionsSynchronize.VisualUpdate,
        returnURL: String?,
        consentPaneModel: FinancialConnectionsConsent?,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.manifest = manifest
        self.visualUpdate = visualUpdate
        self.returnURL = returnURL
        self.consentPaneModel = consentPaneModel
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
        // Use server provided active AuthSession.
        self.authSession = manifest.activeAuthSession
        // If the server returns active institution use that, otherwise resort to initial institution.
        self.institution = manifest.activeInstitution ?? manifest.initialInstitution
        didUpdateManifest()
    }

    func completeFinancialConnectionsSession(terminalError: String?) -> Future<StripeAPI.FinancialConnectionsSession> {
        return apiClient.completeFinancialConnectionsSession(
            clientSecret: clientSecret,
            terminalError: terminalError
        )
    }

    func resetState(withNewManifest newManifest: FinancialConnectionsSessionManifest) {
        authSession = nil
        institution = nil
        paymentAccountResource = nil
        accountNumberLast4 = nil
        linkedAccounts = nil
        manifest = newManifest
    }

    private func didUpdateManifest() {
        analyticsClient.setAdditionalParameters(fromManifest: manifest)
    }
}
