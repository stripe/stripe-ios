//
//  FinancialConnectionsAsyncAPIClient.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-01-07.
//

import Foundation
@_spi(STP) import StripeCore

final class FinancialConnectionsAsyncAPIClient {
    let apiClient: FinancialConnectionsAPIClient
    
    init(apiClient: FinancialConnectionsAPIClient) {
        self.apiClient = apiClient
    }
}

protocol FinancialConnectionsAsyncAPI {
    func synchronize(
        clientSecret: String,
        returnURL: String?
    ) async throws -> FinancialConnectionsSynchronize

    func fetchFinancialConnectionsAccounts(
        clientSecret: String,
        startingAfterAccountId: String?
    ) async throws -> StripeAPI.FinancialConnectionsSession.AccountList

    func fetchFinancialConnectionsSession(clientSecret: String) async throws -> StripeAPI.FinancialConnectionsSession

    func markConsentAcquired(clientSecret: String) async throws -> FinancialConnectionsSessionManifest

    func fetchFeaturedInstitutions(clientSecret: String) async throws -> FinancialConnectionsInstitutionList

    func fetchInstitutions(clientSecret: String, query: String) async throws -> FinancialConnectionsInstitutionSearchResultResource

    func createAuthSession(clientSecret: String, institutionId: String) async throws -> FinancialConnectionsAuthSession

    func cancelAuthSession(clientSecret: String, authSessionId: String) async throws -> FinancialConnectionsAuthSession

    func retrieveAuthSession(
        clientSecret: String,
        authSessionId: String
    ) async throws -> FinancialConnectionsAuthSession

    func fetchAuthSessionOAuthResults(clientSecret: String, authSessionId: String) async throws -> FinancialConnectionsMixedOAuthParams

    func authorizeAuthSession(
        clientSecret: String,
        authSessionId: String,
        publicToken: String?
    ) async throws -> FinancialConnectionsAuthSession

    func fetchAuthSessionAccounts(
        clientSecret: String,
        authSessionId: String,
        initialPollDelay: TimeInterval
    ) async throws -> FinancialConnectionsAuthSessionAccounts

    func selectAuthSessionAccounts(
        clientSecret: String,
        authSessionId: String,
        selectedAccountIds: [String]
    ) async throws -> FinancialConnectionsAuthSessionAccounts

    func markLinkingMoreAccounts(clientSecret: String) async throws -> FinancialConnectionsSessionManifest

    func completeFinancialConnectionsSession(
        clientSecret: String,
        terminalError: String?
    ) async throws -> StripeAPI.FinancialConnectionsSession

    func attachBankAccountToLinkAccountSession(
        clientSecret: String,
        accountNumber: String,
        routingNumber: String,
        consumerSessionClientSecret: String?
    ) async throws -> FinancialConnectionsPaymentAccountResource

    func attachLinkedAccountIdToLinkAccountSession(
        clientSecret: String,
        linkedAccountId: String,
        consumerSessionClientSecret: String?
    ) async throws -> FinancialConnectionsPaymentAccountResource

    func recordAuthSessionEvent(
        clientSecret: String,
        authSessionId: String,
        eventNamespace: String,
        eventName: String
    ) async throws -> EmptyResponse

    // MARK: - Networking

    func saveAccountsToNetworkAndLink(
        shouldPollAccounts: Bool,
        selectedAccounts: [FinancialConnectionsPartnerAccount]?,
        emailAddress: String?,
        phoneNumber: String?,
        country: String?,
        consumerSessionClientSecret: String?,
        clientSecret: String
    ) async throws -> (
        manifest: FinancialConnectionsSessionManifest,
        customSuccessPaneMessage: String?
    )

    func disableNetworking(
        disabledReason: String?,
        clientSuggestedNextPaneOnDisableNetworking: String?,
        clientSecret: String
    ) async throws -> FinancialConnectionsSessionManifest

    func fetchNetworkedAccounts(
        clientSecret: String,
        consumerSessionClientSecret: String
    ) async throws -> FinancialConnectionsNetworkedAccountsResponse

    func selectNetworkedAccounts(
        selectedAccountIds: [String],
        clientSecret: String,
        consumerSessionClientSecret: String,
        consentAcquired: Bool?
    ) async throws -> ShareNetworkedAccountsResponse

    func markLinkStepUpAuthenticationVerified(
        clientSecret: String
    ) async throws -> FinancialConnectionsSessionManifest

    func consumerSessionLookup(
        emailAddress: String,
        clientSecret: String
    ) async throws -> LookupConsumerSessionResponse

    // MARK: - Link API's

    func consumerSessionStartVerification(
        otpType: String,
        customEmailType: String?,
        connectionsMerchantName: String?,
        consumerSessionClientSecret: String
    ) async throws -> ConsumerSessionResponse

    func consumerSessionConfirmVerification(
        otpCode: String,
        otpType: String,
        consumerSessionClientSecret: String
    ) async throws -> ConsumerSessionResponse

    func markLinkVerified(
        clientSecret: String
    ) async throws -> FinancialConnectionsSessionManifest

    func linkAccountSignUp(
        emailAddress: String,
        phoneNumber: String,
        country: String,
        amount: Int?,
        currency: String?,
        incentiveEligibilitySession: ElementsSessionContext.IntentID?
    ) async throws -> LinkSignUpResponse

    func attachLinkConsumerToLinkAccountSession(
        linkAccountSession: String,
        consumerSessionClientSecret: String
    ) async throws -> AttachLinkConsumerToLinkAccountSessionResponse

    func paymentDetails(
        consumerSessionClientSecret: String,
        bankAccountId: String,
        billingAddress: BillingAddress?,
        billingEmail: String?
    ) async throws -> FinancialConnectionsPaymentDetails

    func sharePaymentDetails(
        consumerSessionClientSecret: String,
        paymentDetailsId: String,
        expectedPaymentMethodType: String,
        billingEmail: String?,
        billingPhone: String?
    ) async throws -> FinancialConnectionsSharePaymentDetails

    func paymentMethods(
        consumerSessionClientSecret: String,
        paymentDetailsId: String,
        billingDetails: ElementsSessionContext.BillingDetails?
    ) async throws -> LinkBankPaymentMethod
}

extension FinancialConnectionsAsyncAPIClient: FinancialConnectionsAsyncAPI {
    func synchronize(
        clientSecret: String,
        returnURL: String?
    ) async throws -> FinancialConnectionsSynchronize {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.synchronize(
                clientSecret: clientSecret,
                returnURL: returnURL
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchFinancialConnectionsAccounts(
        clientSecret: String,
        startingAfterAccountId: String?
    ) async throws -> StripeAPI.FinancialConnectionsSession.AccountList {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.fetchFinancialConnectionsAccounts(
                clientSecret: clientSecret,
                startingAfterAccountId: startingAfterAccountId
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchFinancialConnectionsSession(
        clientSecret: String
    ) async throws -> StripeAPI.FinancialConnectionsSession {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.fetchFinancialConnectionsSession(
                clientSecret: clientSecret
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func markConsentAcquired(
        clientSecret: String
    ) async throws -> FinancialConnectionsSessionManifest {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.markConsentAcquired(
                clientSecret: clientSecret
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchFeaturedInstitutions(
        clientSecret: String
    ) async throws -> FinancialConnectionsInstitutionList {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.fetchFeaturedInstitutions(
                clientSecret: clientSecret
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchInstitutions(
        clientSecret: String,
        query: String
    ) async throws -> FinancialConnectionsInstitutionSearchResultResource {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.fetchInstitutions(
                clientSecret: clientSecret,
                query: query
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func createAuthSession(
        clientSecret: String,
        institutionId: String
    ) async throws -> FinancialConnectionsAuthSession {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.createAuthSession(
                clientSecret: clientSecret,
                institutionId: institutionId
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func cancelAuthSession(
        clientSecret: String,
        authSessionId: String
    ) async throws -> FinancialConnectionsAuthSession {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.cancelAuthSession(
                clientSecret: clientSecret,
                authSessionId: authSessionId
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func retrieveAuthSession(
        clientSecret: String,
        authSessionId: String
    ) async throws -> FinancialConnectionsAuthSession {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.retrieveAuthSession(
                clientSecret: clientSecret,
                authSessionId: authSessionId
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchAuthSessionOAuthResults(
        clientSecret: String,
        authSessionId: String
    ) async throws -> FinancialConnectionsMixedOAuthParams {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.fetchAuthSessionOAuthResults(
                clientSecret: clientSecret,
                authSessionId: authSessionId
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func authorizeAuthSession(
        clientSecret: String,
        authSessionId: String,
        publicToken: String?
    ) async throws -> FinancialConnectionsAuthSession {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.authorizeAuthSession(
                clientSecret: clientSecret,
                authSessionId: authSessionId,
                publicToken: publicToken
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchAuthSessionAccounts(
        clientSecret: String,
        authSessionId: String,
        initialPollDelay: TimeInterval
    ) async throws -> FinancialConnectionsAuthSessionAccounts {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.fetchAuthSessionAccounts(
                clientSecret: clientSecret,
                authSessionId: authSessionId,
                initialPollDelay: initialPollDelay
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func selectAuthSessionAccounts(
        clientSecret: String,
        authSessionId: String,
        selectedAccountIds: [String]
    ) async throws -> FinancialConnectionsAuthSessionAccounts {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.selectAuthSessionAccounts(
                clientSecret: clientSecret,
                authSessionId: authSessionId,
                selectedAccountIds: selectedAccountIds
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func markLinkingMoreAccounts(
        clientSecret: String
    ) async throws -> FinancialConnectionsSessionManifest {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.markLinkingMoreAccounts(
                clientSecret: clientSecret
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func completeFinancialConnectionsSession(
        clientSecret: String,
        terminalError: String?
    ) async throws -> StripeAPI.FinancialConnectionsSession {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.completeFinancialConnectionsSession(
                clientSecret: clientSecret,
                terminalError: terminalError
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func attachBankAccountToLinkAccountSession(
        clientSecret: String,
        accountNumber: String,
        routingNumber: String,
        consumerSessionClientSecret: String?
    ) async throws -> FinancialConnectionsPaymentAccountResource {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.attachBankAccountToLinkAccountSession(
                clientSecret: clientSecret,
                accountNumber: accountNumber,
                routingNumber: routingNumber,
                consumerSessionClientSecret: consumerSessionClientSecret
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func attachLinkedAccountIdToLinkAccountSession(
        clientSecret: String,
        linkedAccountId: String,
        consumerSessionClientSecret: String?
    ) async throws -> FinancialConnectionsPaymentAccountResource {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.attachLinkedAccountIdToLinkAccountSession(
                clientSecret: clientSecret,
                linkedAccountId: linkedAccountId,
                consumerSessionClientSecret: consumerSessionClientSecret
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func recordAuthSessionEvent(
        clientSecret: String,
        authSessionId: String,
        eventNamespace: String,
        eventName: String
    ) async throws -> EmptyResponse {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.recordAuthSessionEvent(
                clientSecret: clientSecret,
                authSessionId: authSessionId,
                eventNamespace: eventNamespace,
                eventName: eventName
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func saveAccountsToNetworkAndLink(
        shouldPollAccounts: Bool,
        selectedAccounts: [FinancialConnectionsPartnerAccount]?,
        emailAddress: String?,
        phoneNumber: String?,
        country: String?,
        consumerSessionClientSecret: String?,
        clientSecret: String
    ) async throws -> (
        manifest: FinancialConnectionsSessionManifest,
        customSuccessPaneMessage: String?
    ) {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.saveAccountsToNetworkAndLink(
                shouldPollAccounts: shouldPollAccounts,
                selectedAccounts: selectedAccounts,
                emailAddress: emailAddress,
                phoneNumber: phoneNumber,
                country: country,
                consumerSessionClientSecret: consumerSessionClientSecret,
                clientSecret: clientSecret
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func disableNetworking(
        disabledReason: String?,
        clientSuggestedNextPaneOnDisableNetworking: String?,
        clientSecret: String
    ) async throws -> FinancialConnectionsSessionManifest {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.disableNetworking(
                disabledReason: disabledReason,
                clientSuggestedNextPaneOnDisableNetworking: clientSuggestedNextPaneOnDisableNetworking,
                clientSecret: clientSecret
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchNetworkedAccounts(
        clientSecret: String,
        consumerSessionClientSecret: String
    ) async throws -> FinancialConnectionsNetworkedAccountsResponse {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.fetchNetworkedAccounts(
                clientSecret: clientSecret,
                consumerSessionClientSecret: consumerSessionClientSecret
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func selectNetworkedAccounts(
        selectedAccountIds: [String],
        clientSecret: String,
        consumerSessionClientSecret: String,
        consentAcquired: Bool?
    ) async throws -> ShareNetworkedAccountsResponse {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.selectNetworkedAccounts(
                selectedAccountIds: selectedAccountIds,
                clientSecret: clientSecret,
                consumerSessionClientSecret: consumerSessionClientSecret,
                consentAcquired: consentAcquired
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func markLinkStepUpAuthenticationVerified(
        clientSecret: String
    ) async throws -> FinancialConnectionsSessionManifest {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.markLinkStepUpAuthenticationVerified(
                clientSecret: clientSecret
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func consumerSessionLookup(
        emailAddress: String,
        clientSecret: String
    ) async throws -> LookupConsumerSessionResponse {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.consumerSessionLookup(
                emailAddress: emailAddress,
                clientSecret: clientSecret
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func consumerSessionStartVerification(
        otpType: String,
        customEmailType: String?,
        connectionsMerchantName: String?,
        consumerSessionClientSecret: String
    ) async throws -> ConsumerSessionResponse {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.consumerSessionStartVerification(
                otpType: otpType,
                customEmailType: customEmailType,
                connectionsMerchantName: connectionsMerchantName,
                consumerSessionClientSecret: consumerSessionClientSecret
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func consumerSessionConfirmVerification(
        otpCode: String,
        otpType: String,
        consumerSessionClientSecret: String
    ) async throws -> ConsumerSessionResponse {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.consumerSessionConfirmVerification(
                otpCode: otpCode,
                otpType: otpType,
                consumerSessionClientSecret: consumerSessionClientSecret
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func markLinkVerified(
        clientSecret: String
    ) async throws -> FinancialConnectionsSessionManifest {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.markLinkVerified(
                clientSecret: clientSecret
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func linkAccountSignUp(
        emailAddress: String,
        phoneNumber: String,
        country: String,
        amount: Int?,
        currency: String?,
        incentiveEligibilitySession: ElementsSessionContext.IntentID?
    ) async throws -> LinkSignUpResponse {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.linkAccountSignUp(
                emailAddress: emailAddress,
                phoneNumber: phoneNumber,
                country: country,
                amount: amount,
                currency: currency,
                incentiveEligibilitySession: incentiveEligibilitySession
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func attachLinkConsumerToLinkAccountSession(
        linkAccountSession: String,
        consumerSessionClientSecret: String
    ) async throws -> AttachLinkConsumerToLinkAccountSessionResponse {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.attachLinkConsumerToLinkAccountSession(
                linkAccountSession: linkAccountSession,
                consumerSessionClientSecret: consumerSessionClientSecret
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func paymentDetails(
        consumerSessionClientSecret: String,
        bankAccountId: String,
        billingAddress: BillingAddress?,
        billingEmail: String?
    ) async throws -> FinancialConnectionsPaymentDetails {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.paymentDetails(
                consumerSessionClientSecret: consumerSessionClientSecret,
                bankAccountId: bankAccountId,
                billingAddress: billingAddress,
                billingEmail: billingEmail
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func sharePaymentDetails(
        consumerSessionClientSecret: String,
        paymentDetailsId: String,
        expectedPaymentMethodType: String,
        billingEmail: String?,
        billingPhone: String?
    ) async throws -> FinancialConnectionsSharePaymentDetails {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.sharePaymentDetails(
                consumerSessionClientSecret: consumerSessionClientSecret,
                paymentDetailsId: paymentDetailsId,
                expectedPaymentMethodType: expectedPaymentMethodType,
                billingEmail: billingEmail,
                billingPhone: billingPhone
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func paymentMethods(
        consumerSessionClientSecret: String,
        paymentDetailsId: String,
        billingDetails: ElementsSessionContext.BillingDetails?
    ) async throws -> LinkBankPaymentMethod {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.paymentMethods(
                consumerSessionClientSecret: consumerSessionClientSecret,
                paymentDetailsId: paymentDetailsId,
                billingDetails: billingDetails
            ).observe { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
