//
//  ConsumerSession.swift
//  StripePaymentSheet
//
//  Created by Cameron Sabol on 2/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// For internal SDK use only
final class ConsumerSession: Decodable {
    let clientSecret: String
    let emailAddress: String
    let redactedPhoneNumber: String
    let verificationSessions: [VerificationSession]
    let supportedPaymentDetailsTypes: Set<ConsumerPaymentDetails.DetailsType>

    init(
        clientSecret: String,
        emailAddress: String,
        redactedPhoneNumber: String,
        verificationSessions: [VerificationSession],
        supportedPaymentDetailsTypes: Set<ConsumerPaymentDetails.DetailsType>
    ) {
        self.clientSecret = clientSecret
        self.emailAddress = emailAddress
        self.redactedPhoneNumber = redactedPhoneNumber
        self.verificationSessions = verificationSessions
        self.supportedPaymentDetailsTypes = supportedPaymentDetailsTypes
    }

    private enum CodingKeys: String, CodingKey {
        case clientSecret
        case emailAddress
        case redactedPhoneNumber
        case verificationSessions
        case supportedPaymentDetailsTypes = "supportPaymentDetailsTypes"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.clientSecret = try container.decode(String.self, forKey: .clientSecret)
        self.emailAddress = try container.decode(String.self, forKey: .emailAddress)
        self.redactedPhoneNumber = try container.decode(String.self, forKey: .redactedPhoneNumber)
        self.verificationSessions = try container.decodeIfPresent([ConsumerSession.VerificationSession].self, forKey: .verificationSessions) ?? []
        self.supportedPaymentDetailsTypes = try container.decodeIfPresent(Set<ConsumerPaymentDetails.DetailsType>.self, forKey: .supportedPaymentDetailsTypes) ?? []
    }

}

extension ConsumerSession: Equatable {
    static func ==(lhs: ConsumerSession, rhs: ConsumerSession) -> Bool {
        // NSObject-style equality
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

// MARK: - Helpers
extension ConsumerSession {
    var hasVerifiedSMSSession: Bool {
        verificationSessions.containsVerifiedSMSSession
    }

    var hasStartedSMSVerification: Bool {
        verificationSessions.contains( where: { $0.type == .sms && $0.state == .started })
    }

    var isVerifiedForSignup: Bool {
        verificationSessions.isVerifiedForSignup
    }
}

// MARK: - API methods
extension ConsumerSession {
    class func lookupSession(
        for email: String?,
        with apiClient: STPAPIClient = STPAPIClient.shared,
        cookieStore: LinkCookieStore = LinkSecureCookieStore.shared,
        completion: @escaping (Result<ConsumerSession.LookupResponse, Error>) -> Void
    ) {
        apiClient.lookupConsumerSession(for: email, cookieStore: cookieStore, completion: completion)
    }

    class func signUp(
        email: String,
        phoneNumber: String,
        locale: Locale = .autoupdatingCurrent,
        legalName: String?,
        countryCode: String?,
        consentAction: String?,
        with apiClient: STPAPIClient = STPAPIClient.shared,
        cookieStore: LinkCookieStore = LinkSecureCookieStore.shared,
        completion: @escaping (Result<SessionWithPublishableKey, Error>) -> Void
    ) {
        apiClient.createConsumer(
            for: email,
            with: phoneNumber,
            locale: locale,
            legalName: legalName,
            countryCode: countryCode,
            consentAction: consentAction,
            cookieStore: cookieStore,
            completion: completion
        )
    }

    func createPaymentDetails(
        paymentMethodParams: STPPaymentMethodParams,
        with apiClient: STPAPIClient = STPAPIClient.shared,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        guard paymentMethodParams.type == .card,
              let billingDetails = paymentMethodParams.billingDetails,
              let cardParams = paymentMethodParams.card else {
            DispatchQueue.main.async {
                assertionFailure()
                completion(.failure(NSError.stp_genericConnectionError()))
            }
            return
        }

        apiClient.createPaymentDetails(
            for: clientSecret,
            cardParams: cardParams,
            billingEmailAddress: billingDetails.email ?? emailAddress,
            billingDetails: billingDetails,
            consumerAccountPublishableKey: consumerAccountPublishableKey,
            completion: completion)
    }

    func createPaymentDetails(
        linkedAccountId: String,
        with apiClient: STPAPIClient = STPAPIClient.shared,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        apiClient.createPaymentDetails(
            for: clientSecret,
            linkedAccountId: linkedAccountId,
            consumerAccountPublishableKey: consumerAccountPublishableKey,
            completion: completion)
    }

    func createLinkAccountSession(
        with apiClient: STPAPIClient = STPAPIClient.shared,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<LinkAccountSession, Error>) -> Void
    ) {
        apiClient.createLinkAccountSession(
            for: clientSecret,
            consumerAccountPublishableKey: consumerAccountPublishableKey,
            completion: completion)
    }

    func listPaymentDetails(
        with apiClient: STPAPIClient = STPAPIClient.shared,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<[ConsumerPaymentDetails], Error>) -> Void
    ) {
        apiClient.listPaymentDetails(
            for: clientSecret,
            consumerAccountPublishableKey: consumerAccountPublishableKey,
            completion: completion)
    }

    func deletePaymentDetails(
        with apiClient: STPAPIClient = STPAPIClient.shared,
        id: String,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        apiClient.deletePaymentDetails(
            for: clientSecret,
            id: id,
            consumerAccountPublishableKey: consumerAccountPublishableKey,
            completion: completion)
    }

    func updatePaymentDetails(
        with apiClient: STPAPIClient = STPAPIClient.shared,
        id: String,
        updateParams: UpdatePaymentDetailsParams,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        apiClient.updatePaymentDetails(
            for: clientSecret, id: id,
            updateParams: updateParams,
            consumerAccountPublishableKey: consumerAccountPublishableKey,
            completion: completion)
    }

    func logout(
        with apiClient: STPAPIClient = STPAPIClient.shared,
        cookieStore: LinkCookieStore = LinkSecureCookieStore.shared,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        // Logout from server.
        apiClient.logout(
            consumerSessionClientSecret: clientSecret,
            cookieStore: cookieStore,
            consumerAccountPublishableKey: consumerAccountPublishableKey,
            completion: completion)
    }

}
