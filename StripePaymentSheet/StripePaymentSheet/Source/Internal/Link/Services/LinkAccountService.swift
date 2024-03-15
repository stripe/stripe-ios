//
//  LinkAccountService.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 1/21/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) import StripeCore

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
    ///   - completion: Completion block.
    func lookupAccount(
        withEmail email: String?,
        completion: @escaping (Result<PaymentSheetLinkAccount?, Error>) -> Void
    )
}

final class LinkAccountService: LinkAccountServiceProtocol {

    let apiClient: STPAPIClient

    init(
        apiClient: STPAPIClient = .shared
    ) {
        self.apiClient = apiClient
    }

    func lookupAccount(
        withEmail email: String?,
        completion: @escaping (Result<PaymentSheetLinkAccount?, Error>) -> Void
    ) {
        ConsumerSession.lookupSession(
            for: email,
            with: apiClient
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
                            apiClient: apiClient
                        )
                    ))
                case .notFound:
                    if let email = email {
                        completion(.success(
                            PaymentSheetLinkAccount(
                                email: email,
                                session: nil,
                                publishableKey: nil,
                                apiClient: self.apiClient
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
}
