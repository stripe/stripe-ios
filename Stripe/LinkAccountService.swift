//
//  LinkAccountService.swift
//  StripeiOS
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
    
    /// Checks if we have seen this email log out before
    /// - Parameter email: true if this email has logged out before, false otherwise
    func hasEmailLoggedOut(email: String) -> Bool
}

final class LinkAccountService: LinkAccountServiceProtocol {

    let apiClient: STPAPIClient
    let cookieStore: LinkCookieStore

    /// The default cookie store used by new instances of the service.
    static var defaultCookieStore: LinkCookieStore = LinkSecureCookieStore.shared

    init(
        apiClient: STPAPIClient = .shared,
        cookieStore: LinkCookieStore = defaultCookieStore
    ) {
        self.apiClient = apiClient
        self.cookieStore = cookieStore
    }

    /// Returns true if we have a session cookie stored on device
    var hasSessionCookie: Bool {
        return cookieStore.formattedSessionCookies() != nil
    }

    func lookupAccount(
        withEmail email: String?,
        completion: @escaping (Result<PaymentSheetLinkAccount?, Error>) -> Void
    ) {
        ConsumerSession.lookupSession(for: email, with: apiClient, cookieStore: cookieStore) { lookupResponse, error in
            if let lookupResponse = lookupResponse {
                switch lookupResponse.responseType {
                case .found(let consumerSession):
                    completion(.success(
                        PaymentSheetLinkAccount(
                            email: consumerSession.emailAddress,
                            session: consumerSession,
                            apiClient: self.apiClient,
                            cookieStore: self.cookieStore
                        )
                    ))

                case .notFound(_):
                    if let email = email {
                        completion(.success(
                            PaymentSheetLinkAccount(
                                email: email,
                                session: nil,
                                apiClient: self.apiClient,
                                cookieStore: self.cookieStore
                            )
                        ))
                    } else {
                        completion(.success(nil))
                    }

                case .noAvailableLookupParams:
                    completion(.success(nil))
                }
            } else {
                STPAnalyticsClient.sharedClient.logLink2FAStartFailure()
                completion(.failure(
                    error ?? PaymentSheetError.unknown(debugDescription: "Failed to lookup ConsumerSession")
                ))
            }
        }
    }
    
    func hasEmailLoggedOut(email: String) -> Bool {
        guard let hashedEmail = email.lowercased().sha256 else {
            return false
        }

        return cookieStore.read(key: cookieStore.emailCookieKey) == hashedEmail
    }

}
