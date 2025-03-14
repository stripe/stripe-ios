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
    var configuration: FinancialConnectionsSheet.Configuration { get }
    var reducedBranding: Bool { get }
    var merchantLogo: [String]? { get }
    var returnURL: String? { get }
    var consentPaneModel: FinancialConnectionsConsent? { get }
    var accountPickerPane: FinancialConnectionsAccountPickerPane? { get }
    var apiClient: any FinancialConnectionsAPI { get }
    var clientSecret: String { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    var elementsSessionContext: ElementsSessionContext? { get }
    var reduceManualEntryProminenceInErrors: Bool { get }

    var institution: FinancialConnectionsInstitution? { get set }
    var authSession: FinancialConnectionsAuthSession? { get set }
    var idConsentContent: FinancialConnectionsIDConsentContent? { get set }
    var linkedAccounts: [FinancialConnectionsPartnerAccount]? { get set }
    var terminalError: Error? { get set }
    var errorPaneError: Error? { get set }
    var errorPaneReferrerPane: FinancialConnectionsSessionManifest.NextPane? { get set }
    var paymentAccountResource: FinancialConnectionsPaymentAccountResource? { get set }
    var accountNumberLast4: String? { get set }
    var consumerSession: ConsumerSessionData? { get set }
    var consumerPublishableKey: String? { get set }
    var saveToLinkWithStripeSucceeded: Bool? { get set }
    var lastPaneLaunched: FinancialConnectionsSessionManifest.NextPane? { get set }
    var customSuccessPaneCaption: String? { get set }
    var customSuccessPaneSubCaption: String? { get set }
    var pendingRelinkAuthorization: String? { get set }

    func createPaymentDetails(
        consumerSessionClientSecret: String,
        bankAccountId: String,
        billingAddress: BillingAddress?,
        billingEmail: String?
    ) -> Future<FinancialConnectionsPaymentDetails>
    func resetState(withNewManifest newManifest: FinancialConnectionsSessionManifest)
    func completeFinancialConnectionsSession(terminalError: String?) -> Future<StripeAPI.FinancialConnectionsSession>
}

class NativeFlowAPIDataManager: NativeFlowDataManager {

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
    }
    var reduceManualEntryProminenceInErrors: Bool {
        return visualUpdate.reduceManualEntryProminenceInErrors
    }
    let configuration: FinancialConnectionsSheet.Configuration
    let returnURL: String?
    let consentPaneModel: FinancialConnectionsConsent?
    var idConsentContent: FinancialConnectionsIDConsentContent?
    let accountPickerPane: FinancialConnectionsAccountPickerPane?
    var apiClient: any FinancialConnectionsAPI
    let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    let elementsSessionContext: ElementsSessionContext?

    var institution: FinancialConnectionsInstitution?
    var authSession: FinancialConnectionsAuthSession?
    var linkedAccounts: [FinancialConnectionsPartnerAccount]?
    var terminalError: Error?
    var errorPaneError: Error?
    var errorPaneReferrerPane: FinancialConnectionsSessionManifest.NextPane?
    var paymentAccountResource: FinancialConnectionsPaymentAccountResource?
    var accountNumberLast4: String?
    var saveToLinkWithStripeSucceeded: Bool?
    var lastPaneLaunched: FinancialConnectionsSessionManifest.NextPane?
    var customSuccessPaneCaption: String?
    var customSuccessPaneSubCaption: String?
    var pendingRelinkAuthorization: String?

    var consumerSession: ConsumerSessionData? {
        didSet {
            apiClient.consumerSession = consumerSession
        }
    }

    var consumerPublishableKey: String? {
        didSet {
            apiClient.consumerPublishableKey = consumerPublishableKey
        }
    }

    init(
        manifest: FinancialConnectionsSessionManifest,
        configuration: FinancialConnectionsSheet.Configuration,
        visualUpdate: FinancialConnectionsSynchronize.VisualUpdate,
        returnURL: String?,
        consentPaneModel: FinancialConnectionsConsent?,
        accountPickerPane: FinancialConnectionsAccountPickerPane?,
        apiClient: any FinancialConnectionsAPI,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        elementsSessionContext: ElementsSessionContext?
    ) {
        self.manifest = manifest
        self.configuration = configuration
        self.visualUpdate = visualUpdate
        self.returnURL = returnURL
        self.consentPaneModel = consentPaneModel
        self.accountPickerPane = accountPickerPane
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
        self.elementsSessionContext = elementsSessionContext
        // Use server provided active AuthSession.
        self.authSession = manifest.activeAuthSession
        // If the server returns active institution use that, otherwise resort to initial institution.
        self.institution = manifest.activeInstitution ?? manifest.initialInstitution
        didUpdateManifest()
    }

    func createPaymentDetails(
        consumerSessionClientSecret: String,
        bankAccountId: String,
        billingAddress: BillingAddress?,
        billingEmail: String?
    ) -> Future<FinancialConnectionsPaymentDetails> {
        apiClient.paymentDetails(
            consumerSessionClientSecret: consumerSessionClientSecret,
            bankAccountId: bankAccountId,
            billingAddress: billingAddress,
            billingEmail: billingEmail
        )
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
        apiClient.isLinkWithStripe = manifest.isLinkWithStripe == true
        analyticsClient.setAdditionalParameters(fromManifest: manifest)
    }
}
