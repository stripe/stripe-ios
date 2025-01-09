//
//  FinancialConnectionsAPIClientFacade.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-01-08.
//

import Foundation
@_spi(STP) import StripeCore

final class FinancialConnectionsAPIClientFacade {
    let backingAPIClient: STPAPIClient
    var apiClient: any FinancialConnectionsAPI

    // Passthrough properties:
    var isLinkWithStripe: Bool {
        get {
            apiClient.isLinkWithStripe
        } set {
            apiClient.isLinkWithStripe = newValue
        }
    }

    var consumerPublishableKey: String? {
        get {
            apiClient.consumerPublishableKey
        } set {
            apiClient.consumerPublishableKey = newValue
        }
    }

    var consumerSession: ConsumerSessionData? {
        get {
            apiClient.consumerSession
        } set {
            apiClient.consumerSession = newValue
        }
    }

    init(apiClient: STPAPIClient, shouldUseAsyncClient: Bool) {
        self.backingAPIClient = apiClient
        if shouldUseAsyncClient {
            self.apiClient = FinancialConnectionsAsyncAPIClient(apiClient: apiClient)
        } else {
            self.apiClient = FinancialConnectionsAPIClient(apiClient: apiClient)
        }
    }
}

extension FinancialConnectionsAPIClientFacade: FinancialConnectionsAPI {
    func synchronize(
        clientSecret: String,
        returnURL: String?
    ) -> Future<FinancialConnectionsSynchronize> {
        apiClient.synchronize(
            clientSecret: clientSecret,
            returnURL: returnURL
        )
    }

    func fetchFinancialConnectionsAccounts(
        clientSecret: String,
        startingAfterAccountId: String?
    ) -> Promise<StripeAPI.FinancialConnectionsSession.AccountList> {
        apiClient.fetchFinancialConnectionsAccounts(
            clientSecret: clientSecret,
            startingAfterAccountId: startingAfterAccountId
        )
    }

    func fetchFinancialConnectionsSession(clientSecret: String) -> Promise<StripeAPI.FinancialConnectionsSession> {
        apiClient.fetchFinancialConnectionsSession(
            clientSecret: clientSecret
        )
    }

    func markConsentAcquired(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest> {
        apiClient.markConsentAcquired(
            clientSecret: clientSecret
        )
    }

    func fetchFeaturedInstitutions(clientSecret: String) -> Promise<FinancialConnectionsInstitutionList> {
        apiClient.fetchFeaturedInstitutions(
            clientSecret: clientSecret
        )
    }

    func fetchInstitutions(clientSecret: String, query: String) -> Future<FinancialConnectionsInstitutionSearchResultResource> {
        apiClient.fetchInstitutions(
            clientSecret: clientSecret,
            query: query
        )
    }

    func createAuthSession(clientSecret: String, institutionId: String) -> Promise<FinancialConnectionsAuthSession> {
        apiClient.createAuthSession(
            clientSecret: clientSecret,
            institutionId: institutionId
        )
    }

    func cancelAuthSession(clientSecret: String, authSessionId: String) -> Promise<FinancialConnectionsAuthSession> {
        apiClient.cancelAuthSession(
            clientSecret: clientSecret,
            authSessionId: authSessionId
        )
    }

    func retrieveAuthSession(clientSecret: String, authSessionId: String) -> Future<FinancialConnectionsAuthSession> {
        apiClient.retrieveAuthSession(
            clientSecret: clientSecret,
            authSessionId: authSessionId
        )
    }

    func fetchAuthSessionOAuthResults(clientSecret: String, authSessionId: String) -> Future<FinancialConnectionsMixedOAuthParams> {
        apiClient.fetchAuthSessionOAuthResults(
            clientSecret: clientSecret,
            authSessionId: authSessionId
        )
    }

    func authorizeAuthSession(clientSecret: String, authSessionId: String, publicToken: String?) -> Promise<FinancialConnectionsAuthSession> {
        apiClient.authorizeAuthSession(
            clientSecret: clientSecret,
            authSessionId: authSessionId,
            publicToken: publicToken
        )
    }

    func fetchAuthSessionAccounts(clientSecret: String, authSessionId: String, initialPollDelay: TimeInterval) -> Future<FinancialConnectionsAuthSessionAccounts> {
        apiClient.fetchAuthSessionAccounts(
            clientSecret: clientSecret,
            authSessionId: authSessionId,
            initialPollDelay: initialPollDelay
        )
    }

    func selectAuthSessionAccounts(clientSecret: String, authSessionId: String, selectedAccountIds: [String]) -> Promise<FinancialConnectionsAuthSessionAccounts> {
        apiClient.selectAuthSessionAccounts(
            clientSecret: clientSecret,
            authSessionId: authSessionId,
            selectedAccountIds: selectedAccountIds
        )
    }

    func markLinkingMoreAccounts(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest> {
        apiClient.markLinkingMoreAccounts(
            clientSecret: clientSecret
        )
    }

    func completeFinancialConnectionsSession(clientSecret: String, terminalError: String?) -> Future<StripeAPI.FinancialConnectionsSession> {
        apiClient.completeFinancialConnectionsSession(
            clientSecret: clientSecret,
            terminalError: terminalError
        )
    }

    func attachBankAccountToLinkAccountSession(clientSecret: String, accountNumber: String, routingNumber: String, consumerSessionClientSecret: String?) -> Future<FinancialConnectionsPaymentAccountResource> {
        apiClient.attachBankAccountToLinkAccountSession(
            clientSecret: clientSecret,
            accountNumber: accountNumber,
            routingNumber: routingNumber,
            consumerSessionClientSecret: consumerSessionClientSecret
        )
    }

    func attachLinkedAccountIdToLinkAccountSession(clientSecret: String, linkedAccountId: String, consumerSessionClientSecret: String?) -> Future<FinancialConnectionsPaymentAccountResource> {
        apiClient.attachLinkedAccountIdToLinkAccountSession(
            clientSecret: clientSecret,
            linkedAccountId: linkedAccountId,
            consumerSessionClientSecret: consumerSessionClientSecret
        )
    }

    func recordAuthSessionEvent(clientSecret: String, authSessionId: String, eventNamespace: String, eventName: String) -> Future<EmptyResponse> {
        apiClient.recordAuthSessionEvent(
            clientSecret: clientSecret,
            authSessionId: authSessionId,
            eventNamespace: eventNamespace,
            eventName: eventName
        )
    }

    func saveAccountsToNetworkAndLink(shouldPollAccounts: Bool, selectedAccounts: [FinancialConnectionsPartnerAccount]?, emailAddress: String?, phoneNumber: String?, country: String?, consumerSessionClientSecret: String?, clientSecret: String) -> Future<(manifest: FinancialConnectionsSessionManifest, customSuccessPaneMessage: String?)> {
        apiClient.saveAccountsToNetworkAndLink(
            shouldPollAccounts: shouldPollAccounts,
            selectedAccounts: selectedAccounts,
            emailAddress: emailAddress,
            phoneNumber: phoneNumber,
            country: country,
            consumerSessionClientSecret: consumerSessionClientSecret,
            clientSecret: clientSecret
        )
    }

    func disableNetworking(disabledReason: String?, clientSuggestedNextPaneOnDisableNetworking: String?, clientSecret: String) -> Future<FinancialConnectionsSessionManifest> {
        apiClient.disableNetworking(
            disabledReason: disabledReason,
            clientSuggestedNextPaneOnDisableNetworking: clientSuggestedNextPaneOnDisableNetworking,
            clientSecret: clientSecret
        )
    }

    func fetchNetworkedAccounts(clientSecret: String, consumerSessionClientSecret: String) -> Future<FinancialConnectionsNetworkedAccountsResponse> {
        apiClient.fetchNetworkedAccounts(
            clientSecret: clientSecret,
            consumerSessionClientSecret: consumerSessionClientSecret
        )
    }

    func selectNetworkedAccounts(selectedAccountIds: [String], clientSecret: String, consumerSessionClientSecret: String, consentAcquired: Bool?) -> Future<ShareNetworkedAccountsResponse> {
        apiClient.selectNetworkedAccounts(
            selectedAccountIds: selectedAccountIds,
            clientSecret: clientSecret,
            consumerSessionClientSecret: consumerSessionClientSecret,
            consentAcquired: consentAcquired
        )
    }

    func markLinkStepUpAuthenticationVerified(clientSecret: String) -> Future<FinancialConnectionsSessionManifest> {
        apiClient.markLinkStepUpAuthenticationVerified(
            clientSecret: clientSecret
        )
    }

    func consumerSessionLookup(emailAddress: String, clientSecret: String) -> Future<LookupConsumerSessionResponse> {
        apiClient.consumerSessionLookup(
            emailAddress: emailAddress,
            clientSecret: clientSecret
        )
    }

    func consumerSessionStartVerification(otpType: String, customEmailType: String?, connectionsMerchantName: String?, consumerSessionClientSecret: String) -> Future<ConsumerSessionResponse> {
        apiClient.consumerSessionStartVerification(
            otpType: otpType,
            customEmailType: customEmailType,
            connectionsMerchantName: connectionsMerchantName,
            consumerSessionClientSecret: consumerSessionClientSecret
        )
    }

    func consumerSessionConfirmVerification(otpCode: String, otpType: String, consumerSessionClientSecret: String) -> Future<ConsumerSessionResponse> {
        apiClient.consumerSessionConfirmVerification(
            otpCode: otpCode,
            otpType: otpType,
            consumerSessionClientSecret: consumerSessionClientSecret
        )
    }

    func markLinkVerified(clientSecret: String) -> Future<FinancialConnectionsSessionManifest> {
        apiClient.markLinkVerified(
            clientSecret: clientSecret
        )
    }

    func linkAccountSignUp(emailAddress: String, phoneNumber: String, country: String, amount: Int?, currency: String?, incentiveEligibilitySession: ElementsSessionContext.IntentID?) -> Future<LinkSignUpResponse> {
        apiClient.linkAccountSignUp(
            emailAddress: emailAddress,
            phoneNumber: phoneNumber,
            country: country,
            amount: amount,
            currency: currency,
            incentiveEligibilitySession: incentiveEligibilitySession
        )
    }

    func attachLinkConsumerToLinkAccountSession(linkAccountSession: String, consumerSessionClientSecret: String) -> Future<AttachLinkConsumerToLinkAccountSessionResponse> {
        apiClient.attachLinkConsumerToLinkAccountSession(
            linkAccountSession: linkAccountSession,
            consumerSessionClientSecret: consumerSessionClientSecret
        )
    }

    func paymentDetails(consumerSessionClientSecret: String, bankAccountId: String, billingAddress: BillingAddress?, billingEmail: String?) -> Future<FinancialConnectionsPaymentDetails> {
        apiClient.paymentDetails(
            consumerSessionClientSecret: consumerSessionClientSecret,
            bankAccountId: bankAccountId,
            billingAddress: billingAddress,
            billingEmail: billingEmail
        )
    }

    func sharePaymentDetails(consumerSessionClientSecret: String, paymentDetailsId: String, expectedPaymentMethodType: String, billingEmail: String?, billingPhone: String?) -> Future<FinancialConnectionsSharePaymentDetails> {
        apiClient.sharePaymentDetails(
            consumerSessionClientSecret: consumerSessionClientSecret,
            paymentDetailsId: paymentDetailsId,
            expectedPaymentMethodType: expectedPaymentMethodType,
            billingEmail: billingEmail,
            billingPhone: billingPhone
        )
    }

    func paymentMethods(consumerSessionClientSecret: String, paymentDetailsId: String, billingDetails: ElementsSessionContext.BillingDetails?) -> Future<LinkBankPaymentMethod> {
        apiClient.paymentMethods(
            consumerSessionClientSecret: consumerSessionClientSecret,
            paymentDetailsId: paymentDetailsId,
            billingDetails: billingDetails
        )
    }
}
