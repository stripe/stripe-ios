//
//  AuthFlowDataManager.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/7/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol AuthFlowDataManager: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get }
    var authorizationSession: FinancialConnectionsAuthorizationSession? { get }
    var institution: FinancialConnectionsInstitution? { get }
    var paymentAccountResource: FinancialConnectionsPaymentAccountResource? { get }
    var accountNumberLast4: String? { get }
    var linkedAccounts: [FinancialConnectionsPartnerAccount]? { get }
    var terminalError: Error? { get }
    var delegate: AuthFlowDataManagerDelegate? { get set }
    
    // MARK: - Read Calls
    
    func nextPane() -> FinancialConnectionsSessionManifest.NextPane

    // MARK: - Mutating Calls
    
    func completeFinancialConnectionsSession() -> Future<StripeAPI.FinancialConnectionsSession>
    func didConsent(withManifest manifest: FinancialConnectionsSessionManifest)
    func startManualEntry()
    func picked(institution: FinancialConnectionsInstitution)
    func didCompletePartnerAuth(authSession: FinancialConnectionsAuthorizationSession)
    func didSelectAccounts(_ linkedAccounts: [FinancialConnectionsPartnerAccount], skipToSuccess: Bool)
    func didCompleteManualEntry(
        withPaymentAccountResource paymentAccountResource: FinancialConnectionsPaymentAccountResource,
        accountNumberLast4: String
    )
    func startResetFlow()
    func resetFlowDidSucceeedMarkLinkingMoreAccounts(manifest: FinancialConnectionsSessionManifest)
    func startTerminalError(error: Error)
}

protocol AuthFlowDataManagerDelegate: AnyObject {
    func authFlowDataManagerDidUpdateNextPane(_ dataManager: AuthFlowDataManager)
    func authFlowDataManagerDidUpdateManifest(_ dataManager: AuthFlowDataManager)
    func authFlow(dataManager: AuthFlowDataManager,
                  failedToUpdateManifest error: Error)
    func authFlowDataManagerDidRequestToClose(
        _ dataManager: AuthFlowDataManager,
        showConfirmationAlert: Bool,
        error: Error?
    )
}

class AuthFlowAPIDataManager: AuthFlowDataManager {
    
    // MARK: - Types
    
    struct VersionedNextPane {
        let pane: FinancialConnectionsSessionManifest.NextPane
        let version: Int
    }

    // MARK: - Properties
    
    weak var delegate: AuthFlowDataManagerDelegate?
    private(set) var manifest: FinancialConnectionsSessionManifest {
        didSet {
            delegate?.authFlowDataManagerDidUpdateManifest(self)
        }
    }
    private let api: FinancialConnectionsAPIClient
    private let clientSecret: String
    
    private(set) var authorizationSession: FinancialConnectionsAuthorizationSession?
    private(set) var institution: FinancialConnectionsInstitution?
    private(set) var paymentAccountResource: FinancialConnectionsPaymentAccountResource?
    private(set) var accountNumberLast4: String?
    private(set) var linkedAccounts: [FinancialConnectionsPartnerAccount]?
    private(set) var terminalError: Error?
    private var currentNextPane: VersionedNextPane {
        didSet {
            delegate?.authFlowDataManagerDidUpdateNextPane(self)
        }
    }
    // WARNING: every time we add new state, we should check whether it should be cleared as part of `linking more accounts`

    // MARK: - Init
    
    init(with initial: FinancialConnectionsSessionManifest,
         api: FinancialConnectionsAPIClient,
         clientSecret: String) {
        self.manifest = initial
        self.currentNextPane = VersionedNextPane(pane: initial.nextPane, version: 0)
        self.api = api
        self.clientSecret = clientSecret
    }

    // MARK: - FlowDataManager
    
    func nextPane() -> FinancialConnectionsSessionManifest.NextPane {
        return currentNextPane.pane
    }
    
    func completeFinancialConnectionsSession() -> Future<StripeAPI.FinancialConnectionsSession> {
        return api.completeFinancialConnectionsSession(clientSecret: clientSecret)
    }

    func didConsent(withManifest manifest: FinancialConnectionsSessionManifest) {
        self.manifest = manifest
        let version = currentNextPane.version + 1
        update(nextPane: manifest.nextPane, for: version)
    }
    
    func startManualEntry() {
        let version = currentNextPane.version + 1
        self.update(nextPane: .manualEntry, for: version)
    }
    
    func picked(institution: FinancialConnectionsInstitution) {
        self.institution = institution
        let version = currentNextPane.version + 1
        update(nextPane: .partnerAuth, for: version)
    }
    
    func didCompletePartnerAuth(authSession: FinancialConnectionsAuthorizationSession) {
        self.authorizationSession = authSession
        
        let version = currentNextPane.version + 1
        update(nextPane: .accountPicker, for: version)
        print("^ didCompletePartnerAuth called \(Date())") // TODO(kgaidis): this is temporarily here to debug an issue where account picker appears twice?
    }
    
    func didSelectAccounts(_ linkedAccounts: [FinancialConnectionsPartnerAccount], skipToSuccess: Bool) {
        self.linkedAccounts = linkedAccounts
        
        if skipToSuccess {
            let version = currentNextPane.version + 1
            update(nextPane: .success, for: version)
        } else {
            let shouldAttachLinkedPaymentMethod = manifest.paymentMethodType != nil
            if shouldAttachLinkedPaymentMethod {
                let version = currentNextPane.version + 1
                update(nextPane: .attachLinkedPaymentAccount, for: version)
            } else {
                let version = currentNextPane.version + 1
                update(nextPane: .success, for: version)
            }
        }
    }
    
    func didCompleteManualEntry(
        withPaymentAccountResource paymentAccountResource: FinancialConnectionsPaymentAccountResource,
        accountNumberLast4: String
    ) {
        self.paymentAccountResource = paymentAccountResource
        self.accountNumberLast4 = accountNumberLast4
        
        if manifest.manualEntryUsesMicrodeposits {
            let version = currentNextPane.version + 1
            update(nextPane: .manualEntrySuccess, for: version)
        } else {
            delegate?.authFlowDataManagerDidRequestToClose(self, showConfirmationAlert: false, error: nil)
        }
    }
    
    func startResetFlow() {
        let version = currentNextPane.version + 1
        update(nextPane: .resetFlow, for: version)
    }
    
    func resetFlowDidSucceeedMarkLinkingMoreAccounts(manifest: FinancialConnectionsSessionManifest) {
        // reset state
        self.authorizationSession = nil
        self.institution = nil
        self.paymentAccountResource = nil
        self.accountNumberLast4 = nil
        self.linkedAccounts = nil
        self.manifest = manifest
        
        let version = currentNextPane.version + 1
        update(nextPane: manifest.nextPane, for: version)
    }
    
    func startTerminalError(error: Error) {
        self.terminalError = error
        let version = currentNextPane.version + 1
        update(nextPane: .terminalError, for: version)
    }
}

// MARK: - Helpers

private extension AuthFlowAPIDataManager {
    func update(nextPane: FinancialConnectionsSessionManifest.NextPane, for version: Int) {
        if version > self.currentNextPane.version {
            self.currentNextPane = VersionedNextPane(pane: nextPane, version: version)
        }
    }
}
