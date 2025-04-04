//
//  FinancialConnectionsAPI.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-03-31.
//

import Foundation
@_spi(STP) import StripeCore

protocol FinancialConnectionsAPI {
    typealias SaveAccountsToNetworkAndLinkResponse = (
        manifest: FinancialConnectionsSessionManifest,
        customSuccessPaneMessage: String?
    )

    var backingAPIClient: STPAPIClient { get }

    var isLinkWithStripe: Bool { get set }
    var consumerPublishableKey: String? { get set }
    var consumerSession: ConsumerSessionData? { get set }

    func completeAssertion(
        possibleError: Error?,
        api: FinancialConnectionsAPIClientLogger.API,
        pane: FinancialConnectionsSessionManifest.NextPane
    ) -> Error?

    func synchronize(
        clientSecret: String,
        returnURL: String?,
        initialSynchronize: Bool
    ) -> Future<FinancialConnectionsSynchronize>

    func fetchFinancialConnectionsAccounts(
        clientSecret: String,
        startingAfterAccountId: String?
    ) -> Promise<StripeAPI.FinancialConnectionsSession.AccountList>

    func fetchFinancialConnectionsSession(clientSecret: String) -> Promise<StripeAPI.FinancialConnectionsSession>

    func markConsentAcquired(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest>

    func fetchFeaturedInstitutions(clientSecret: String) -> Promise<FinancialConnectionsInstitutionList>

    func fetchInstitutions(clientSecret: String, query: String) -> Future<FinancialConnectionsInstitutionSearchResultResource>

    func createAuthSession(clientSecret: String, institutionId: String) -> Promise<FinancialConnectionsAuthSession>

    func repairAuthSession(clientSecret: String, coreAuthorization: String) -> Promise<FinancialConnectionsRepairSession>

    func cancelAuthSession(clientSecret: String, authSessionId: String) -> Promise<FinancialConnectionsAuthSession>

    func selectInstitution(clientSecret: String, institutionId: String) -> Promise<FinancialConnectionsSelectInstitution>

    func retrieveAuthSession(
        clientSecret: String,
        authSessionId: String
    ) -> Future<FinancialConnectionsAuthSession>

    func retrieveAuthSessionPolling(
        clientSecret: String,
        authSessionId: String
    ) -> Future<FinancialConnectionsAuthSession>

    func fetchAuthSessionOAuthResults(clientSecret: String, authSessionId: String) -> Future<
        FinancialConnectionsMixedOAuthParams
    >

    func authorizeAuthSession(
        clientSecret: String,
        authSessionId: String,
        publicToken: String?
    ) -> Promise<FinancialConnectionsAuthSession>

    func fetchAuthSessionAccounts(
        clientSecret: String,
        authSessionId: String,
        initialPollDelay: TimeInterval
    ) -> Future<FinancialConnectionsAuthSessionAccounts>

    func selectAuthSessionAccounts(
        clientSecret: String,
        authSessionId: String,
        selectedAccountIds: [String]
    ) -> Promise<FinancialConnectionsAuthSessionAccounts>

    func markLinkingMoreAccounts(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest>

    func completeFinancialConnectionsSession(
        clientSecret: String,
        terminalError: String?
    ) -> Future<StripeAPI.FinancialConnectionsSession>

    func attachBankAccountToLinkAccountSession(
        clientSecret: String,
        accountNumber: String,
        routingNumber: String,
        consumerSessionClientSecret: String?
    ) -> Future<FinancialConnectionsPaymentAccountResource>

    func attachLinkedAccountIdToLinkAccountSession(
        clientSecret: String,
        linkedAccountId: String,
        consumerSessionClientSecret: String?
    ) -> Future<FinancialConnectionsPaymentAccountResource>

    func recordAuthSessionEvent(
        clientSecret: String,
        authSessionId: String,
        eventNamespace: String,
        eventName: String
    ) -> Future<EmptyResponse>

    // MARK: - Networking

    func saveAccountsToNetworkAndLink(
        shouldPollAccounts: Bool,
        selectedAccounts: [FinancialConnectionsPartnerAccount]?,
        emailAddress: String?,
        phoneNumber: String?,
        country: String?,
        consumerSessionClientSecret: String?,
        clientSecret: String,
        isRelink: Bool
    ) -> Future<SaveAccountsToNetworkAndLinkResponse>

    func disableNetworking(
        disabledReason: String?,
        clientSuggestedNextPaneOnDisableNetworking: String?,
        clientSecret: String
    ) -> Future<FinancialConnectionsSessionManifest>

    func fetchNetworkedAccounts(
        clientSecret: String,
        consumerSessionClientSecret: String
    ) -> Future<FinancialConnectionsNetworkedAccountsResponse>

    func selectNetworkedAccounts(
        selectedAccountIds: [String],
        clientSecret: String,
        consumerSessionClientSecret: String,
        consentAcquired: Bool?
    ) -> Future<ShareNetworkedAccountsResponse>

    func markLinkStepUpAuthenticationVerified(
        clientSecret: String
    ) -> Future<FinancialConnectionsSessionManifest>

    func consumerSessionLookup(
        emailAddress: String,
        clientSecret: String,
        sessionId: String,
        emailSource: FinancialConnectionsAsyncAPIClient.EmailSource,
        useMobileEndpoints: Bool,
        pane: FinancialConnectionsSessionManifest.NextPane
    ) -> Future<LookupConsumerSessionResponse>

    // MARK: - Link API's

    func consumerSessionStartVerification(
        otpType: String,
        customEmailType: String?,
        connectionsMerchantName: String?,
        consumerSessionClientSecret: String
    ) -> Future<ConsumerSessionResponse>

    func consumerSessionConfirmVerification(
        otpCode: String,
        otpType: String,
        consumerSessionClientSecret: String
    ) -> Future<ConsumerSessionResponse>

    func markLinkVerified(
        clientSecret: String
    ) -> Future<FinancialConnectionsSessionManifest>

    func linkAccountSignUp(
        emailAddress: String,
        phoneNumber: String,
        country: String,
        amount: Int?,
        currency: String?,
        incentiveEligibilitySession: ElementsSessionContext.IntentID?,
        useMobileEndpoints: Bool,
        pane: FinancialConnectionsSessionManifest.NextPane
    ) -> Future<LinkSignUpResponse>

    func attachLinkConsumerToLinkAccountSession(
        linkAccountSession: String,
        consumerSessionClientSecret: String
    ) -> Future<AttachLinkConsumerToLinkAccountSessionResponse>

    func paymentDetails(
        consumerSessionClientSecret: String,
        bankAccountId: String,
        billingAddress: BillingAddress?,
        billingEmail: String?
    ) -> Future<FinancialConnectionsPaymentDetails>

    func sharePaymentDetails(
        consumerSessionClientSecret: String,
        paymentDetailsId: String,
        expectedPaymentMethodType: String,
        billingEmail: String?,
        billingPhone: String?
    ) -> Future<FinancialConnectionsSharePaymentDetails>

    func paymentMethods(
        consumerSessionClientSecret: String,
        paymentDetailsId: String,
        billingDetails: ElementsSessionContext.BillingDetails?
    ) -> Future<LinkBankPaymentMethod>

    func updateAvailableIncentives(
        consumerSessionClientSecret: String,
        sessionID: String,
        paymentDetailsID: String
    ) -> Future<AvailableIncentives>
}
