//
//  FinancialConnectionsAsyncAPIClient+Wrappers.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-01-08.
//

import Foundation
@_spi(STP) import StripeCore

extension FinancialConnectionsAsyncAPIClient {
    /// Wraps an `async` function into returning a `Future`.
    private func wrapAsyncToFuture<T>(_ asyncFunction: @escaping () async throws -> T) -> Future<T> {
        let promise = Promise<T>()
        Task {
            do {
                let result = try await asyncFunction()
                promise.resolve(with: result)
            } catch {
                promise.reject(with: error)
            }
        }
        return promise
    }

    /// Wraps an `async` function into returning a `Promise`.
    private func wrapAsyncToPromise<T>(_ asyncFunction: @escaping () async throws -> T) -> Promise<T> {
        let promise = Promise<T>()
        Task {
            do {
                let result = try await asyncFunction()
                promise.resolve(with: result)
            } catch {
                promise.reject(with: error)
            }
        }
        return promise
    }
}

// Conforms to `FinancialConnectionsAPI` for facade purposes.
// Some `FinancialConnectionsAPI` methods return a `Promise`, and others return a `Future`.
// Both of these approaches are functionally equivalent.
extension FinancialConnectionsAsyncAPIClient: FinancialConnectionsAPI {
    func synchronize(
        clientSecret: String,
        returnURL: String?,
        initialSynchronize: Bool
    ) -> Future<FinancialConnectionsSynchronize> {
        wrapAsyncToFuture {
            try await self.synchronize(
                clientSecret: clientSecret,
                returnURL: returnURL,
                initialSynchronize: initialSynchronize
            )
        }
    }

    func fetchFinancialConnectionsAccounts(clientSecret: String, startingAfterAccountId: String?) -> Promise<StripeAPI.FinancialConnectionsSession.AccountList> {
        wrapAsyncToPromise {
            try await self.fetchFinancialConnectionsAccounts(
                clientSecret: clientSecret,
                startingAfterAccountId: startingAfterAccountId
            )
        }
    }

    func fetchFinancialConnectionsSession(
        clientSecret: String
    ) -> Promise<StripeAPI.FinancialConnectionsSession> {
        wrapAsyncToPromise {
            try await self.fetchFinancialConnectionsSession(clientSecret: clientSecret)
        }
    }

    func markConsentAcquired(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest> {
        wrapAsyncToPromise {
            try await self.markConsentAcquired(clientSecret: clientSecret)
        }
    }

    func fetchFeaturedInstitutions(clientSecret: String) -> Promise<FinancialConnectionsInstitutionList> {
        wrapAsyncToPromise {
            try await self.fetchFeaturedInstitutions(clientSecret: clientSecret)
        }
    }

    func fetchInstitutions(
        clientSecret: String,
        query: String
    ) -> Future<FinancialConnectionsInstitutionSearchResultResource> {
        wrapAsyncToFuture {
            try await self.fetchInstitutions(clientSecret: clientSecret, query: query)
        }
    }

    func createAuthSession(
        clientSecret: String,
        institutionId: String
    ) -> Promise<FinancialConnectionsAuthSession> {
        wrapAsyncToPromise {
            try await self.createAuthSession(clientSecret: clientSecret, institutionId: institutionId)
        }
    }

    func selectInstitution(clientSecret: String, institutionId: String) -> Promise<FinancialConnectionsSelectInstitution> {
        wrapAsyncToPromise {
            try await self.selectInstitution(clientSecret: clientSecret, institutionId: institutionId)
        }
    }

    func repairAuthSession(clientSecret: String, coreAuthorization: String) -> Promise<FinancialConnectionsRepairSession> {
        wrapAsyncToPromise {
            try await self.repairAuthSession(clientSecret: clientSecret, coreAuthorization: coreAuthorization)
        }
    }

    func cancelAuthSession(
        clientSecret: String,
        authSessionId: String
    ) -> Promise<FinancialConnectionsAuthSession> {
        wrapAsyncToPromise {
            try await self.cancelAuthSession(clientSecret: clientSecret, authSessionId: authSessionId)
        }
    }

    func retrieveAuthSession(
        clientSecret: String,
        authSessionId: String
    ) -> Future<FinancialConnectionsAuthSession> {
        wrapAsyncToFuture {
            try await self.retrieveAuthSession(clientSecret: clientSecret, authSessionId: authSessionId)
        }
    }

    func retrieveAuthSessionPolling(
        clientSecret: String,
        authSessionId: String
    ) -> Future<FinancialConnectionsAuthSession> {
        wrapAsyncToFuture {
            try await self.retrieveAuthSessionPolling(clientSecret: clientSecret, authSessionId: authSessionId)
        }
    }

    func fetchAuthSessionOAuthResults(
        clientSecret: String,
        authSessionId: String
    ) -> Future<FinancialConnectionsMixedOAuthParams> {
        wrapAsyncToFuture {
            try await self.fetchAuthSessionOAuthResults(
                clientSecret: clientSecret,
                authSessionId: authSessionId
            )
        }
    }

    func authorizeAuthSession(
        clientSecret: String,
        authSessionId: String,
        publicToken: String?
    ) -> Promise<FinancialConnectionsAuthSession> {
        wrapAsyncToPromise {
            try await self.authorizeAuthSession(
                clientSecret: clientSecret,
                authSessionId: authSessionId,
                publicToken: publicToken
            )
        }
    }

    func fetchAuthSessionAccounts(
        clientSecret: String,
        authSessionId: String,
        initialPollDelay: TimeInterval
    ) -> Future<FinancialConnectionsAuthSessionAccounts> {
        wrapAsyncToFuture {
            try await self.fetchAuthSessionAccounts(
                clientSecret: clientSecret,
                authSessionId: authSessionId,
                initialPollDelay: initialPollDelay
            )
        }
    }

    func selectAuthSessionAccounts(
        clientSecret: String,
        authSessionId: String,
        selectedAccountIds: [String]
    ) -> Promise<FinancialConnectionsAuthSessionAccounts> {
        wrapAsyncToPromise {
            try await self.selectAuthSessionAccounts(
                clientSecret: clientSecret,
                authSessionId: authSessionId,
                selectedAccountIds: selectedAccountIds
            )
        }
    }

    func markLinkingMoreAccounts(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest> {
        wrapAsyncToPromise {
            try await self.markLinkingMoreAccounts(clientSecret: clientSecret)
        }
    }

    func completeFinancialConnectionsSession(
        clientSecret: String,
        terminalError: String?
    ) -> Future<StripeAPI.FinancialConnectionsSession> {
        wrapAsyncToFuture {
            try await self.completeFinancialConnectionsSession(
                clientSecret: clientSecret,
                terminalError: terminalError
            )
        }
    }

    func attachBankAccountToLinkAccountSession(
        clientSecret: String,
        accountNumber: String,
        routingNumber: String,
        consumerSessionClientSecret: String?
    ) -> Future<FinancialConnectionsPaymentAccountResource> {
        wrapAsyncToFuture {
            try await self.attachBankAccountToLinkAccountSession(
                clientSecret: clientSecret,
                accountNumber: accountNumber,
                routingNumber: routingNumber,
                consumerSessionClientSecret: consumerSessionClientSecret
            )
        }
    }

    func attachLinkedAccountIdToLinkAccountSession(
        clientSecret: String,
        linkedAccountId: String,
        consumerSessionClientSecret: String?
    ) -> Future<FinancialConnectionsPaymentAccountResource> {
        wrapAsyncToFuture {
            try await self.attachLinkedAccountIdToLinkAccountSession(
                clientSecret: clientSecret,
                linkedAccountId: linkedAccountId,
                consumerSessionClientSecret: consumerSessionClientSecret
            )
        }
    }

    func recordAuthSessionEvent(
        clientSecret: String,
        authSessionId: String,
        eventNamespace: String,
        eventName: String
    ) -> Future<EmptyResponse> {
        wrapAsyncToFuture {
            try await self.recordAuthSessionEvent(
                clientSecret: clientSecret,
                authSessionId: authSessionId,
                eventNamespace: eventNamespace,
                eventName: eventName
            )
        }
    }

    func saveAccountsToNetworkAndLink(
        shouldPollAccounts: Bool,
        selectedAccounts: [FinancialConnectionsPartnerAccount]?,
        emailAddress: String?,
        phoneNumber: String?,
        country: String?,
        consumerSessionClientSecret: String?,
        clientSecret: String,
        isRelink: Bool
    ) -> Future<(manifest: FinancialConnectionsSessionManifest, customSuccessPaneMessage: String?)> {
        wrapAsyncToFuture {
            try await self.saveAccountsToNetworkAndLink(
                shouldPollAccounts: shouldPollAccounts,
                selectedAccounts: selectedAccounts,
                emailAddress: emailAddress,
                phoneNumber: phoneNumber,
                country: country,
                consumerSessionClientSecret: consumerSessionClientSecret,
                clientSecret: clientSecret,
                isRelink: isRelink
            )
        }
    }

    func disableNetworking(
        disabledReason: String?,
        clientSuggestedNextPaneOnDisableNetworking: String?,
        clientSecret: String
    ) -> Future<FinancialConnectionsSessionManifest> {
        wrapAsyncToFuture {
            try await self.disableNetworking(
                disabledReason: disabledReason,
                clientSuggestedNextPaneOnDisableNetworking: clientSuggestedNextPaneOnDisableNetworking,
                clientSecret: clientSecret
            )
        }
    }

    func fetchNetworkedAccounts(
        clientSecret: String,
        consumerSessionClientSecret: String
    ) -> Future<FinancialConnectionsNetworkedAccountsResponse> {
        wrapAsyncToFuture {
            try await self.fetchNetworkedAccounts(
                clientSecret: clientSecret,
                consumerSessionClientSecret: consumerSessionClientSecret
            )
        }
    }

    func selectNetworkedAccounts(
        selectedAccountIds: [String],
        clientSecret: String,
        consumerSessionClientSecret: String,
        consentAcquired: Bool?
    ) -> Future<ShareNetworkedAccountsResponse> {
        wrapAsyncToFuture {
            try await self.selectNetworkedAccounts(
                selectedAccountIds: selectedAccountIds,
                clientSecret: clientSecret,
                consumerSessionClientSecret: consumerSessionClientSecret,
                consentAcquired: consentAcquired
            )
        }
    }

    func markLinkStepUpAuthenticationVerified(
        clientSecret: String
    ) -> Future<FinancialConnectionsSessionManifest> {
        wrapAsyncToFuture {
            try await self.markLinkStepUpAuthenticationVerified(clientSecret: clientSecret)
        }
    }

    func consumerSessionLookup(
        emailAddress: String,
        clientSecret: String,
        sessionId: String,
        emailSource: FinancialConnectionsAsyncAPIClient.EmailSource,
        useMobileEndpoints: Bool,
        pane: FinancialConnectionsSessionManifest.NextPane
    ) -> Future<LookupConsumerSessionResponse> {
        wrapAsyncToFuture {
            try await self.consumerSessionLookup(
                emailAddress: emailAddress,
                clientSecret: clientSecret,
                sessionId: sessionId,
                emailSource: emailSource,
                useMobileEndpoints: useMobileEndpoints,
                pane: pane
            )
        }
    }

    func consumerSessionStartVerification(
        otpType: String,
        customEmailType: String?,
        connectionsMerchantName: String?,
        consumerSessionClientSecret: String
    ) -> Future<ConsumerSessionResponse> {
        wrapAsyncToFuture {
            try await self.consumerSessionStartVerification(
                otpType: otpType,
                customEmailType: customEmailType,
                connectionsMerchantName: connectionsMerchantName,
                consumerSessionClientSecret: consumerSessionClientSecret
            )
        }
    }

    func consumerSessionConfirmVerification(
        otpCode: String,
        otpType: String,
        consumerSessionClientSecret: String
    ) -> Future<ConsumerSessionResponse> {
        wrapAsyncToFuture {
            try await self.consumerSessionConfirmVerification(
                otpCode: otpCode,
                otpType: otpType,
                consumerSessionClientSecret: consumerSessionClientSecret
            )
        }
    }

    func markLinkVerified(
        clientSecret: String
    ) -> Future<FinancialConnectionsSessionManifest> {
        wrapAsyncToFuture {
            try await self.markLinkVerified(clientSecret: clientSecret)
        }
    }

    func linkAccountSignUp(
        emailAddress: String,
        phoneNumber: String,
        country: String,
        amount: Int?,
        currency: String?,
        incentiveEligibilitySession: ElementsSessionContext.IntentID?,
        useMobileEndpoints: Bool,
        pane: FinancialConnectionsSessionManifest.NextPane
    ) -> Future<LinkSignUpResponse> {
        wrapAsyncToFuture {
            try await self.linkAccountSignUp(
                emailAddress: emailAddress,
                phoneNumber: phoneNumber,
                country: country,
                amount: amount,
                currency: currency,
                incentiveEligibilitySession: incentiveEligibilitySession,
                useMobileEndpoints: useMobileEndpoints,
                pane: pane
            )
        }
    }

    func attachLinkConsumerToLinkAccountSession(
        linkAccountSession: String,
        consumerSessionClientSecret: String
    ) -> Future<AttachLinkConsumerToLinkAccountSessionResponse> {
        wrapAsyncToFuture {
            try await self.attachLinkConsumerToLinkAccountSession(
                linkAccountSession: linkAccountSession,
                consumerSessionClientSecret: consumerSessionClientSecret
            )
        }
    }

    func paymentDetails(
        consumerSessionClientSecret: String,
        bankAccountId: String,
        billingAddress: BillingAddress?,
        billingEmail: String?
    ) -> Future<FinancialConnectionsPaymentDetails> {
        wrapAsyncToFuture {
            try await self.paymentDetails(
                consumerSessionClientSecret: consumerSessionClientSecret,
                bankAccountId: bankAccountId,
                billingAddress: billingAddress,
                billingEmail: billingEmail
            )
        }
    }

    func sharePaymentDetails(
        consumerSessionClientSecret: String,
        paymentDetailsId: String,
        expectedPaymentMethodType: String,
        billingEmail: String?,
        billingPhone: String?
    ) -> Future<FinancialConnectionsSharePaymentDetails> {
        wrapAsyncToFuture {
            try await self.sharePaymentDetails(
                consumerSessionClientSecret: consumerSessionClientSecret,
                paymentDetailsId: paymentDetailsId,
                expectedPaymentMethodType: expectedPaymentMethodType,
                billingEmail: billingEmail,
                billingPhone: billingPhone
            )
        }
    }

    func paymentMethods(
        consumerSessionClientSecret: String,
        paymentDetailsId: String,
        billingDetails: ElementsSessionContext.BillingDetails?
    ) -> Future<LinkBankPaymentMethod> {
        wrapAsyncToFuture {
            try await self.paymentMethods(
                consumerSessionClientSecret: consumerSessionClientSecret,
                paymentDetailsId: paymentDetailsId,
                billingDetails: billingDetails
            )
        }
    }

    func updateAvailableIncentives(
        consumerSessionClientSecret: String,
        sessionID: String,
        paymentDetailsID: String
    ) -> Future<AvailableIncentives> {
        wrapAsyncToFuture {
            try await self.updateAvailableIncentives(
                consumerSessionClientSecret: consumerSessionClientSecret,
                sessionID: sessionID,
                paymentDetailsID: paymentDetailsID
            )
        }
    }
}
