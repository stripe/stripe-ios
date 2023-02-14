//
//  EmptyFinancialConnectionsAPIClient.swift
//  StripeFinancialConnectionsTests
//
//  Created by Krisjanis Gaidis on 1/20/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@testable import StripeFinancialConnections

class EmptyFinancialConnectionsAPIClient: FinancialConnectionsAPIClient {
    func fetchFinancialConnectionsAccounts(clientSecret: String, startingAfterAccountId: String?) -> Promise<
        StripeAPI.FinancialConnectionsSession.AccountList
    > {
        return Promise<StripeAPI.FinancialConnectionsSession.AccountList>()
    }

    func fetchFinancialConnectionsSession(clientSecret: String) -> Promise<StripeAPI.FinancialConnectionsSession> {
        return Promise<StripeAPI.FinancialConnectionsSession>()
    }

    func generateSessionManifest(clientSecret: String, returnURL: String?) -> Promise<FinancialConnectionsSynchronize> {
        return Promise<FinancialConnectionsSynchronize>()
    }

    func markConsentAcquired(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest> {
        return Promise<FinancialConnectionsSessionManifest>()
    }

    func fetchFeaturedInstitutions(clientSecret: String) -> Promise<FinancialConnectionsInstitutionList> {
        return Promise<FinancialConnectionsInstitutionList>()
    }

    func fetchInstitutions(clientSecret: String, query: String) -> Promise<FinancialConnectionsInstitutionList> {
        return Promise<FinancialConnectionsInstitutionList>()
    }

    func createAuthSession(clientSecret: String, institutionId: String) -> Promise<FinancialConnectionsAuthSession> {
        return Promise<FinancialConnectionsAuthSession>()
    }

    func cancelAuthSession(clientSecret: String, authSessionId: String) -> Promise<FinancialConnectionsAuthSession> {
        return Promise<FinancialConnectionsAuthSession>()
    }

    func fetchAuthSessionOAuthResults(clientSecret: String, authSessionId: String) -> Future<
        FinancialConnectionsMixedOAuthParams
    > {
        return Promise<FinancialConnectionsMixedOAuthParams>()
    }

    func authorizeAuthSession(clientSecret: String, authSessionId: String, publicToken: String?) -> Promise<
        FinancialConnectionsAuthSession
    > {
        return Promise<FinancialConnectionsAuthSession>()
    }

    func fetchAuthSessionAccounts(
        clientSecret: String,
        authSessionId: String,
        initialPollDelay: TimeInterval
    ) -> Future<FinancialConnectionsAuthSessionAccounts> {
        return Promise<FinancialConnectionsAuthSessionAccounts>()
    }

    func selectAuthSessionAccounts(clientSecret: String, authSessionId: String, selectedAccountIds: [String])
        -> Promise<FinancialConnectionsAuthSessionAccounts>
    {
        return Promise<FinancialConnectionsAuthSessionAccounts>()
    }

    func markLinkingMoreAccounts(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest> {
        return Promise<FinancialConnectionsSessionManifest>()
    }

    func completeFinancialConnectionsSession(
        clientSecret: String,
        terminalError: String?
    ) -> Future<StripeAPI.FinancialConnectionsSession> {
        return Promise<StripeAPI.FinancialConnectionsSession>()
    }

    func attachBankAccountToLinkAccountSession(
        clientSecret: String,
        accountNumber: String,
        routingNumber: String
    ) -> Future<FinancialConnectionsPaymentAccountResource> {
        return Promise<FinancialConnectionsPaymentAccountResource>()
    }

    func attachLinkedAccountIdToLinkAccountSession(
        clientSecret: String,
        linkedAccountId: String,
        consumerSessionClientSecret: String?
    ) -> Future<FinancialConnectionsPaymentAccountResource> {
        return Promise<FinancialConnectionsPaymentAccountResource>()
    }

    func recordAuthSessionEvent(
        clientSecret: String,
        authSessionId: String,
        eventNamespace: String,
        eventName: String
    ) -> Future<EmptyResponse> {
        return Promise<EmptyResponse>()
    }
}
