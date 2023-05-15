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

    func synchronize(clientSecret: String, returnURL: String?) -> Promise<FinancialConnectionsSynchronize> {
        return Promise<FinancialConnectionsSynchronize>()
    }

    func markConsentAcquired(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest> {
        return Promise<FinancialConnectionsSessionManifest>()
    }

    func fetchFeaturedInstitutions(clientSecret: String) -> Promise<FinancialConnectionsInstitutionList> {
        return Promise<FinancialConnectionsInstitutionList>()
    }

    func fetchInstitutions(clientSecret: String, query: String) -> Future<FinancialConnectionsInstitutionSearchResultResource> {
        return Promise<FinancialConnectionsInstitutionSearchResultResource>()
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

    func saveAccountsToLink(
        emailAddress: String?,
        phoneNumber: String?,
        country: String?,
        selectedAccountIds: [String],
        consumerSessionClientSecret: String?,
        clientSecret: String
    ) -> Future<StripeFinancialConnections.FinancialConnectionsSessionManifest> {
        return Promise<StripeFinancialConnections.FinancialConnectionsSessionManifest>()
    }

    func disableNetworking(
        disabledReason: String?,
        clientSecret: String
    ) -> Future<FinancialConnectionsSessionManifest> {
        Promise<StripeFinancialConnections.FinancialConnectionsSessionManifest>()
    }

    func fetchNetworkedAccounts(
        clientSecret: String,
        consumerSessionClientSecret: String
    ) -> StripeCore.Future<StripeFinancialConnections.FinancialConnectionsNetworkedAccountsResponse> {
        return Promise<StripeFinancialConnections.FinancialConnectionsNetworkedAccountsResponse>()
    }

    func markLinkVerified(
        clientSecret: String
    ) -> StripeCore.Future<StripeFinancialConnections.FinancialConnectionsSessionManifest> {
        return Promise<StripeFinancialConnections.FinancialConnectionsSessionManifest>()
    }

    func selectNetworkedAccounts(
        selectedAccountIds: [String],
        clientSecret: String,
        consumerSessionClientSecret: String
    ) -> StripeCore.Future<StripeFinancialConnections.FinancialConnectionsInstitutionList> {
        return Promise<StripeFinancialConnections.FinancialConnectionsInstitutionList>()
    }

    func consumerSessionLookup(
        emailAddress: String,
        clientSecret: String
    ) -> Future<StripeFinancialConnections.LookupConsumerSessionResponse> {
        return Promise<StripeFinancialConnections.LookupConsumerSessionResponse>()
    }

    func consumerSessionStartVerification(
        otpType: String,
        customEmailType: String?,
        connectionsMerchantName: String?,
        consumerSessionClientSecret: String
    ) -> StripeCore.Future<StripeFinancialConnections.ConsumerSessionResponse> {
        return Promise<StripeFinancialConnections.ConsumerSessionResponse>()
    }

    func consumerSessionConfirmVerification(
        otpCode: String,
        otpType: String,
        consumerSessionClientSecret: String
    ) -> StripeCore.Future<StripeFinancialConnections.ConsumerSessionResponse> {
        return Promise<StripeFinancialConnections.ConsumerSessionResponse>()
    }

    func markLinkStepUpAuthenticationVerified(
        clientSecret: String
    ) -> Future<FinancialConnectionsSessionManifest> {
        return Promise<StripeFinancialConnections.FinancialConnectionsSessionManifest>()
    }
}
