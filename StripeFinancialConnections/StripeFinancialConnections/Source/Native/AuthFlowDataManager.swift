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
    var authorizationSession: FinancialConnectionsAuthorizationSession? { get set }
    var linkedAccounts: [FinancialConnectionsPartnerAccount]? { get set }
    var terminalError: Error? { get set }
    var paymentAccountResource: FinancialConnectionsPaymentAccountResource? { get set }
    var accountNumberLast4: String? { get set }
    
    func resetState(withNewManifest newManifest: FinancialConnectionsSessionManifest)
    func completeFinancialConnectionsSession() -> Future<StripeAPI.FinancialConnectionsSession>
}

class AuthFlowAPIDataManager: AuthFlowDataManager {

    var manifest: FinancialConnectionsSessionManifest
    private let api: FinancialConnectionsAPIClient
    private let clientSecret: String
    
    var institution: FinancialConnectionsInstitution?
    var authorizationSession: FinancialConnectionsAuthorizationSession?
    var linkedAccounts: [FinancialConnectionsPartnerAccount]?
    var terminalError: Error?
    var paymentAccountResource: FinancialConnectionsPaymentAccountResource?
    var accountNumberLast4: String?

    init(
        with initial: FinancialConnectionsSessionManifest,
        api: FinancialConnectionsAPIClient,
        clientSecret: String
    ) {
        self.manifest = initial
        self.api = api
        self.clientSecret = clientSecret
    }
    
    func completeFinancialConnectionsSession() -> Future<StripeAPI.FinancialConnectionsSession> {
        return api.completeFinancialConnectionsSession(clientSecret: clientSecret)
    }

    func resetState(withNewManifest newManifest: FinancialConnectionsSessionManifest) {
        authorizationSession = nil
        institution = nil
        paymentAccountResource = nil
        accountNumberLast4 = nil
        linkedAccounts = nil
        manifest = newManifest
    }
}
