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
    ///   - completion: Completion block.
    func lookupAccount(
        withEmail email: String?,
        emailSource: EmailSource,
        doNotLogConsumerFunnelEvent: Bool,
        completion: @escaping (Result<PaymentSheetLinkAccount?, Error>) -> Void
    )
}

final class LinkAccountService: LinkAccountServiceProtocol {

    let apiClient: STPAPIClient
    let cookieStore: LinkCookieStore
    let sessionID: String
    let customerID: String?
    let useMobileEndpoints: Bool

    /// The default cookie store used by new instances of the service.
    static var defaultCookieStore: LinkCookieStore = LinkSecureCookieStore.shared

    convenience init(
        apiClient: STPAPIClient = .shared,
        cookieStore: LinkCookieStore = defaultCookieStore,
        elementsSession: STPElementsSession
    ) {
        let shouldPassCustomerIdToLookup = elementsSession.linkSettings?.linkEnableDisplayableDefaultValuesInECE == true

        self.init(
            apiClient: apiClient,
            cookieStore: cookieStore,
            useMobileEndpoints: elementsSession.linkSettings?.useAttestationEndpoints ?? false,
            sessionID: elementsSession.sessionID,
            customerID: elementsSession.customer?.customerSession.customer,
            shouldPassCustomerIdToLookup: shouldPassCustomerIdToLookup
        )
    }

    init(
        apiClient: STPAPIClient = .shared,
        cookieStore: LinkCookieStore = defaultCookieStore,
        useMobileEndpoints: Bool,
        sessionID: String,
        customerID: String?,
        shouldPassCustomerIdToLookup: Bool
    ) {
        self.apiClient = apiClient
        self.cookieStore = cookieStore
        self.useMobileEndpoints = useMobileEndpoints
        self.sessionID = sessionID
        self.customerID = shouldPassCustomerIdToLookup ? customerID : nil
    }

    func lookupAccount(
        withEmail email: String?,
        emailSource: EmailSource,
        doNotLogConsumerFunnelEvent: Bool,
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
            doNotLogConsumerFunnelEvent: doNotLogConsumerFunnelEvent
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
                            useMobileEndpoints: self.useMobileEndpoints
                        )
                    ))
                case .notFound:
                    if let email = email {
                        completion(.success(
                            PaymentSheetLinkAccount(
                                email: email,
                                session: nil,
                                publishableKey: nil,
                                displayablePaymentDetails: nil,
                                apiClient: self.apiClient,
                                useMobileEndpoints: self.useMobileEndpoints
                            )
                        ))
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

    func hasEmailLoggedOut(email: String) -> Bool {
        guard let hashedEmail = email.lowercased().sha256 else {
            return false
        }

        return cookieStore.read(key: .lastLogoutEmail) == hashedEmail
    }

    func getLastSignUpEmail() -> String? {
        return cookieStore.read(key: .lastSignupEmail)
    }
}
