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
        ConsumerSession.lookupSession(
            for: email,
            with: apiClient,
            cookieStore: cookieStore
        ) { [apiClient, cookieStore] result in
            switch result {
            case .success(let lookupResponse):
                switch lookupResponse.responseType {
                case .found(let session):
                    completion(.success(
                        PaymentSheetLinkAccount(
                            email: session.consumerSession.emailAddress,
                            session: session.consumerSession,
                            publishableKey: session.publishableKey,
                            apiClient: apiClient,
                            cookieStore: cookieStore
                        )
                    ))
                case .notFound:
                    if let email = email {
                        completion(.success(
                            PaymentSheetLinkAccount(
                                email: email,
                                session: nil,
                                publishableKey: nil,
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
            case .failure(let error):
                STPAnalyticsClient.sharedClient.logLinkAccountLookupFailure()
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

    func getLastPMDetails() -> LinkPMDisplayDetails? {
        if let lastBrandString = cookieStore.read(key: .lastPMBrand),
           let last4 = cookieStore.read(key: .lastPMLast4) {
            let brand = STPCard.brand(from: lastBrandString)
            return LinkPMDisplayDetails(last4: last4, brand: brand)
        }
        return nil
    }

    func setLastPMDetails(newDetails: LinkPMDisplayDetails?) {
        if let newDetails = newDetails,
            let brandString = STPCardBrandUtilities.stringFrom(newDetails.brand) {
            cookieStore.write(key: .lastPMBrand, value: brandString, allowSync: false)
            cookieStore.write(key: .lastPMLast4, value: newDetails.last4, allowSync: false)
        } else {
            cookieStore.delete(key: .lastPMBrand)
            cookieStore.delete(key: .lastPMLast4)
        }
    }

    func setLastPMDetails(params: STPPaymentMethodParams) {
        if let last4 = params.card?.last4,
           let number = params.card?.number
        {
            let brand = STPCardValidator.brand(forNumber: number)
            let pmDetails = LinkPMDisplayDetails(last4: last4, brand: brand)
            self.setLastPMDetails(newDetails: pmDetails)
        } else {
            self.setLastPMDetails(newDetails: nil)
        }
    }

    func setLastPMDetails(pm: STPPaymentMethod) {
        if let last4 = pm.card?.last4,
           let brand = pm.card?.brand
        {
            let pmDetails = LinkPMDisplayDetails(last4: last4, brand: brand)
            self.setLastPMDetails(newDetails: pmDetails)
        } else {
            self.setLastPMDetails(newDetails: nil)
        }
    }

}
