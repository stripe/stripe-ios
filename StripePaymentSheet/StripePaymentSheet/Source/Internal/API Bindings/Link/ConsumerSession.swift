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
    let verificationSessions: [VerificationSession]

    init(
        clientSecret: String,
        emailAddress: String,
        verificationSessions: [VerificationSession]
    ) {
        self.clientSecret = clientSecret
        self.emailAddress = emailAddress
        self.verificationSessions = verificationSessions
    }

    private enum CodingKeys: String, CodingKey {
        case clientSecret
        case emailAddress
        case verificationSessions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.clientSecret = try container.decode(String.self, forKey: .clientSecret)
        self.emailAddress = try container.decode(String.self, forKey: .emailAddress)
        self.verificationSessions = try container.decodeIfPresent([ConsumerSession.VerificationSession].self, forKey: .verificationSessions) ?? []
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
        completion: @escaping (Result<ConsumerSession.LookupResponse, Error>) -> Void
    ) {
        apiClient.lookupConsumerSession(for: email, completion: completion)
    }

    class func signUp(
        email: String,
        phoneNumber: String,
        locale: Locale = .autoupdatingCurrent,
        legalName: String?,
        countryCode: String?,
        consentAction: String?,
        with apiClient: STPAPIClient = STPAPIClient.shared,
        completion: @escaping (Result<SessionWithPublishableKey, Error>) -> Void
    ) {
        apiClient.createConsumer(
            for: email,
            with: phoneNumber,
            locale: locale,
            legalName: legalName,
            countryCode: countryCode,
            consentAction: consentAction,
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
              let cardParams = paymentMethodParams.card else {
            DispatchQueue.main.async {
                completion(.failure(NSError.stp_genericConnectionError()))
            }
            return
        }

        let country = paymentMethodParams.nonnil_billingDetails.nonnil_address.country
        if country?.isBlank ?? true {
            // Country is the only required billing detail. If it's empty, fall back to the locale country
            paymentMethodParams.nonnil_billingDetails.nonnil_address.country = Locale.current.stp_regionCode
        }

        apiClient.createPaymentDetails(
            for: clientSecret,
            cardParams: cardParams,
            billingEmailAddress: paymentMethodParams.nonnil_billingDetails.email ?? emailAddress,
            billingDetails: paymentMethodParams.nonnil_billingDetails,
            consumerAccountPublishableKey: consumerAccountPublishableKey,
            completion: completion)
    }

    func sharePaymentDetails(
        with apiClient: STPAPIClient = STPAPIClient.shared,
        id: String,
        cvc: String?,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<PaymentDetailsShareResponse, Error>) -> Void
    ) {
        apiClient.sharePaymentDetails(
            for: clientSecret,
            id: id,
            consumerAccountPublishableKey: consumerAccountPublishableKey,
            cvc: cvc,
            completion: completion)
    }

    func logout(
        with apiClient: STPAPIClient = STPAPIClient.shared,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        apiClient.logout(
            consumerSessionClientSecret: clientSecret,
            consumerAccountPublishableKey: consumerAccountPublishableKey,
            completion: completion)
    }

}
