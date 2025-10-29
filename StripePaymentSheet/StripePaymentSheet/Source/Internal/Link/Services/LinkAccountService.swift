//
//  LinkAccountService.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 1/21/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) import StripeCore
@_exported @_spi(STP) import StripePayments

/// Provides a method for looking up Link accounts by email.
protocol LinkAccountServiceProtocol {
    /// Looks up an account by email.
    ///
    /// The `email` parameter is optional and objects that conform to this protocol
    /// can fallback to a session management mechanisms (such as cookies), to return
    /// the current account.
    ///
    /// When an email is provided and no account is not found, the method must return transient
    /// account object that can be used for finalizing the signup process.
    ///
    /// - Parameters:
    ///   - email: Email address associated with the account.
    ///   - emailSource: Details on the source of the email used.
    ///   - doNotLogConsumerFunnelEvent: Whether or not this lookup call should be logged backend side.
    ///   - requestSurface: The request surface to use for the API call. `.default` will map to `ios_payment_element`.
    ///   - completion: Completion block.
    func lookupAccount(
        withEmail email: String?,
        emailSource: EmailSource,
        doNotLogConsumerFunnelEvent: Bool,
        requestSurface: LinkRequestSurface,
        completion: @escaping (Result<PaymentSheetLinkAccount?, Error>) -> Void
    )

    /// Looks up an account by link auth token.
    /// - Parameters:
    ///   - linkAuthTokenClientSecret: An encrypted one-time-use auth token that, upon successful validation, leaves the Link account’s consumer session in an already-verified state, allowing the client to skip verification.
    ///   - requestSurface: The request surface to use for the API call. `.default` will map to `ios_payment_element`.
    ///   - completion: Completion block.
    func lookupLinkAuthToken(
        _ linkAuthTokenClientSecret: String,
        requestSurface: LinkRequestSurface,
        completion: @escaping (Result<PaymentSheetLinkAccount?, Error>) -> Void
    )

    /// Looks up an account by Link Auth Intent ID.
    ///
    /// - Parameters:
    ///   - linkAuthIntentID: The Link Auth Intent ID to look up.
    ///   - requestSurface: The request surface to use for the API call. `.default` will map to `ios_payment_element`.
    ///   - completion: Completion block.
    func lookupLinkAuthIntent(
        linkAuthIntentID: String,
        requestSurface: LinkRequestSurface,
        completion: @escaping (Result<LookupLinkAuthIntentResponse?, Error>) -> Void
    )
}

final class LinkAccountService: LinkAccountServiceProtocol {

    let apiClient: STPAPIClient
    let sessionID: String
    let customerID: String?
    let useMobileEndpoints: Bool
    let canSyncAttestationState: Bool
    let merchantLogoUrl: URL?

    convenience init(
        apiClient: STPAPIClient = .shared,
        elementsSession: STPElementsSession
    ) {
        let shouldPassCustomerIdToLookup = elementsSession.linkSettings?.linkEnableDisplayableDefaultValuesInECE == true

        self.init(
            apiClient: apiClient,
            useMobileEndpoints: elementsSession.linkSettings?.useAttestationEndpoints ?? false,
            canSyncAttestationState: elementsSession.linkSettings?.attestationStateSyncEnabled ?? false,
            sessionID: elementsSession.sessionID,
            customerID: elementsSession.customer?.customerSession.customer,
            shouldPassCustomerIdToLookup: shouldPassCustomerIdToLookup,
            merchantLogoUrl: elementsSession.merchantLogoUrl
        )
    }

    init(
        apiClient: STPAPIClient = .shared,
        useMobileEndpoints: Bool,
        canSyncAttestationState: Bool,
        sessionID: String,
        customerID: String?,
        shouldPassCustomerIdToLookup: Bool,
        merchantLogoUrl: URL?
    ) {
        self.apiClient = apiClient
        self.useMobileEndpoints = useMobileEndpoints
        self.canSyncAttestationState = canSyncAttestationState
        self.sessionID = sessionID
        self.customerID = shouldPassCustomerIdToLookup ? customerID : nil
        self.merchantLogoUrl = merchantLogoUrl
    }

    func lookupAccount(
        withEmail email: String?,
        emailSource: EmailSource,
        doNotLogConsumerFunnelEvent: Bool,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<PaymentSheetLinkAccount?, Error>) -> Void
    ) {
        guard LinkEmailHelper.canLookupEmail(email) else {
            completion(.success(nil))
            return
        }

        ConsumerSession.lookupSession(
            for: email,
            emailSource: emailSource,
            sessionID: sessionID,
            customerID: customerID,
            with: apiClient,
            useMobileEndpoints: useMobileEndpoints,
            canSyncAttestationState: canSyncAttestationState,
            doNotLogConsumerFunnelEvent: doNotLogConsumerFunnelEvent,
            requestSurface: requestSurface
        ) { [apiClient] result in
            switch result {
            case .success(let lookupResponse):
                STPAnalyticsClient.sharedClient.logLinkAccountLookupComplete(lookupResult: lookupResponse.responseType)
                switch lookupResponse.responseType {
                case .found(let session):
                    completion(.success(
                        PaymentSheetLinkAccount(
                            email: session.consumerSession.emailAddress,
                            session: session.consumerSession,
                            publishableKey: session.publishableKey,
                            displayablePaymentDetails: session.displayablePaymentDetails,
                            apiClient: apiClient,
                            useMobileEndpoints: self.useMobileEndpoints,
                            canSyncAttestationState: self.canSyncAttestationState,
                            requestSurface: requestSurface
                        )
                    ))
                case .notFound(_, let suggestedEmail):
                    if let email = email {
                        let linkAccount = PaymentSheetLinkAccount(
                            email: email,
                            session: nil,
                            publishableKey: nil,
                            displayablePaymentDetails: nil,
                            apiClient: self.apiClient,
                            useMobileEndpoints: self.useMobileEndpoints,
                            canSyncAttestationState: self.canSyncAttestationState,
                            requestSurface: requestSurface
                        )
                        linkAccount.suggestedEmail = suggestedEmail
                        completion(.success(linkAccount))
                    } else {
                        completion(.success(nil))
                    }
                case .noAvailableLookupParams:
                    completion(.success(nil))
                }
            case .failure(let error):
                STPAnalyticsClient.sharedClient.logLinkAccountLookupFailure(error: error)
                completion(.failure(error))
            }
        }
    }

    func lookupLinkAuthToken(
        _ linkAuthTokenClientSecret: String,
        requestSurface: LinkRequestSurface,
        completion: @escaping (Result<PaymentSheetLinkAccount?, Error>) -> Void
    ) {
        ConsumerSession.lookupLinkAuthToken(
            linkAuthTokenClientSecret,
            sessionID: sessionID,
            customerID: customerID,
            useMobileEndpoints: useMobileEndpoints,
            canSyncAttestationState: canSyncAttestationState,
            requestSurface: requestSurface
        ) { [apiClient] result in
            switch result {
            case .success(let lookupResponse):
                STPAnalyticsClient.sharedClient.logLinkAccountLookupComplete(lookupResult: lookupResponse.responseType)
                switch lookupResponse.responseType {
                case .found(let session):
                    completion(.success(
                        PaymentSheetLinkAccount(
                            email: session.consumerSession.emailAddress,
                            session: session.consumerSession,
                            publishableKey: session.publishableKey,
                            displayablePaymentDetails: session.displayablePaymentDetails,
                            apiClient: apiClient,
                            useMobileEndpoints: self.useMobileEndpoints,
                            canSyncAttestationState: self.canSyncAttestationState,
                            requestSurface: requestSurface
                        )
                    ))
                case .notFound, .noAvailableLookupParams:
                    completion(.success(nil))
                }
            case .failure(let error):
                STPAnalyticsClient.sharedClient.logLinkAccountLookupFailure(error: error)
                completion(.failure(error))
            }
        }
    }

    /// Looks up an account by Link Auth Intent ID.
    ///
    /// - Parameters:
    ///   - linkAuthIntentID: The Link Auth Intent ID to look up.
    ///   - requestSurface: The request surface to use for the API call. `.default` will map to `ios_payment_element`.
    ///   - completion: Completion block.
    func lookupLinkAuthIntent(
        linkAuthIntentID: String,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<LookupLinkAuthIntentResponse?, Error>) -> Void
    ) {
        ConsumerSession.lookupLinkAuthIntent(
            linkAuthIntentID: linkAuthIntentID,
            sessionID: sessionID,
            customerID: customerID,
            with: apiClient,
            useMobileEndpoints: useMobileEndpoints,
            canSyncAttestationState: canSyncAttestationState,
            requestSurface: requestSurface
        ) { [weak self, apiClient] result in
            guard let self else { return }
            switch result {
            case .success(let lookupResponse):
                STPAnalyticsClient.sharedClient.logLinkAccountLookupComplete(lookupResult: lookupResponse.responseType)
                switch lookupResponse.responseType {
                case .found(let session):
                    let linkAccount = PaymentSheetLinkAccount(
                        email: session.consumerSession.emailAddress,
                        session: session.consumerSession,
                        publishableKey: session.publishableKey,
                        displayablePaymentDetails: session.displayablePaymentDetails,
                        apiClient: apiClient,
                        useMobileEndpoints: self.useMobileEndpoints,
                        canSyncAttestationState: self.canSyncAttestationState,
                        requestSurface: requestSurface,
                        createdFromAuthIntentID: true
                    )
                    let consentViewModel = LinkConsentViewModel(
                        email: session.consumerSession.emailAddress,
                        merchantLogoURL: self.merchantLogoUrl,
                        dataModel: session.consentDataModel
                    )
                    let response = LookupLinkAuthIntentResponse(linkAccount: linkAccount, consentViewModel: consentViewModel)
                    completion(.success(response))
                case .notFound:
                    completion(.success(nil))
                case .noAvailableLookupParams:
                    completion(.success(nil))
                }
            case .failure(let error):
                STPAnalyticsClient.sharedClient.logLinkAccountLookupFailure(error: error)
                completion(.failure(error))
            }
        }
    }
}
