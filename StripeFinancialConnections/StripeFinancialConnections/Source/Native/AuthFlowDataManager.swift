//
//  AuthFlowDataManager.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/7/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol AuthFlowDataManager: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get set }
    var institution: FinancialConnectionsInstitution? { get set }
    var authorizationSession: FinancialConnectionsAuthorizationSession? { get }
    var paymentAccountResource: FinancialConnectionsPaymentAccountResource? { get }
    var accountNumberLast4: String? { get }
    var linkedAccounts: [FinancialConnectionsPartnerAccount]? { get }
    var terminalError: Error? { get set }
    var delegate: AuthFlowDataManagerDelegate? { get set }
    
    // MARK: - Read Calls
    
    func nextPane() -> FinancialConnectionsSessionManifest.NextPane

    // MARK: - Mutating Calls
    
    func resetState(withNewManifest newManifest: FinancialConnectionsSessionManifest)
    
    func completeFinancialConnectionsSession() -> Future<StripeAPI.FinancialConnectionsSession>
    func didCompletePartnerAuth(authSession: FinancialConnectionsAuthorizationSession)
    func didSelectAccounts(_ linkedAccounts: [FinancialConnectionsPartnerAccount], skipToSuccess: Bool)
    func didCompleteManualEntry(
        withPaymentAccountResource paymentAccountResource: FinancialConnectionsPaymentAccountResource,
        accountNumberLast4: String
    )
    func didCompleteAttachedLinkedPaymentAccount(
        paymentAccountResource: FinancialConnectionsPaymentAccountResource
    )
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
    var manifest: FinancialConnectionsSessionManifest {
        didSet {
            delegate?.authFlowDataManagerDidUpdateManifest(self)
        }
    }
    private let api: FinancialConnectionsAPIClient
    private let clientSecret: String
    
    var institution: FinancialConnectionsInstitution?
    private(set) var authorizationSession: FinancialConnectionsAuthorizationSession?
    private(set) var paymentAccountResource: FinancialConnectionsPaymentAccountResource?
    private(set) var accountNumberLast4: String?
    private(set) var linkedAccounts: [FinancialConnectionsPartnerAccount]?
    var terminalError: Error?
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
    
    func setManifest(_ manifest: FinancialConnectionsSessionManifest) {
        self.manifest = manifest
    }
    
    func nextPane() -> FinancialConnectionsSessionManifest.NextPane {
        return currentNextPane.pane
    }
    
    func completeFinancialConnectionsSession() -> Future<StripeAPI.FinancialConnectionsSession> {
        return api.completeFinancialConnectionsSession(clientSecret: clientSecret)
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
    
    func resetState(withNewManifest newManifest: FinancialConnectionsSessionManifest) {
        authorizationSession = nil
        institution = nil
        paymentAccountResource = nil
        accountNumberLast4 = nil
        linkedAccounts = nil
        manifest = newManifest
    }
    
    func didCompleteAttachedLinkedPaymentAccount(
        paymentAccountResource: FinancialConnectionsPaymentAccountResource
    ) {
        let version = currentNextPane.version + 1
        update(nextPane: paymentAccountResource.nextPane, for: version)
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
