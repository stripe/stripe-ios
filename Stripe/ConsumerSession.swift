//
//  ConsumerSession.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 2/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore

/// For internal SDK use only
@objc(STP_Internal_ConsumerSession)
class ConsumerSession: NSObject, STPAPIResponseDecodable {
    
    let clientSecret: String
    let emailAddress: String
    let redactedPhoneNumber: String
    let verificationSessions: [VerificationSession]
    let authSessionClientSecret: String?
    
    let supportedPaymentDetailsTypes: [ConsumerPaymentDetails.DetailsType]?
    
    let allResponseFields: [AnyHashable : Any]

    init(
        clientSecret: String,
        emailAddress: String,
        redactedPhoneNumber: String,
        verificationSessions: [VerificationSession],
        authSessionClientSecret: String?,
        supportedPaymentDetailsTypes: [ConsumerPaymentDetails.DetailsType]?,
        allResponseFields: [AnyHashable : Any]
    ) {
        self.clientSecret = clientSecret
        self.emailAddress = emailAddress
        self.redactedPhoneNumber = redactedPhoneNumber
        self.verificationSessions = verificationSessions
        self.authSessionClientSecret = authSessionClientSecret
        self.supportedPaymentDetailsTypes = supportedPaymentDetailsTypes
        self.allResponseFields = allResponseFields
        super.init()
    }
    
    static func decodedObject(fromAPIResponse response: [AnyHashable : Any]?) -> Self? {
        guard let response = response,
              let dict = response["consumer_session"] as? [AnyHashable: Any],
              let clientSecret = dict["client_secret"] as? String,
              let emailAddress = dict["email_address"] as? String,
              let redactedPhoneNumber = dict["redacted_phone_number"] as? String
        else {
            return nil
        }
        
        var verificationSessions = [VerificationSession]()
        if let sessions = dict["verification_sessions"] as? [[AnyHashable: Any]] {
            for session in sessions {
                if let parsedSession = VerificationSession.decodedObject(fromAPIResponse: session) {
                    verificationSessions.append(parsedSession)
                }
            }
        }

        let authSessionClientSecret = response["auth_session_client_secret"] as? String

        let supportedPaymentDetailsTypeStrings = dict["support_payment_details_types"] as? [String]

        let supportedPaymentDetailsTypes = supportedPaymentDetailsTypeStrings?.compactMap {
            ConsumerPaymentDetails.DetailsType(rawValue: $0.lowercased())
        }

        return ConsumerSession(clientSecret: clientSecret,
                               emailAddress: emailAddress,
                               redactedPhoneNumber: redactedPhoneNumber,
                               verificationSessions: verificationSessions,
                               authSessionClientSecret: authSessionClientSecret,
                               supportedPaymentDetailsTypes: supportedPaymentDetailsTypes,
                               allResponseFields: dict) as? Self
    }

}

// MARK: - Cookie Management

extension ConsumerSession {
    func updateCookie(withStore store: LinkCookieStore) {
        store.updateSessionCookie(with: authSessionClientSecret)
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
        completion: @escaping (Result<ConsumerSession.SignupResponse, Error>) -> Void
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
            billingEmailAddress: emailAddress,
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

    func startVerification(
        type: VerificationSession.SessionType = .sms,
        locale: Locale = .autoupdatingCurrent,
        with apiClient: STPAPIClient = STPAPIClient.shared,
        cookieStore: LinkCookieStore = LinkSecureCookieStore.shared,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        apiClient.startVerification(
            for: clientSecret,
            type: type,
            locale: locale,
            cookieStore: cookieStore,
            consumerAccountPublishableKey: consumerAccountPublishableKey,
            completion: completion)
    }

    func confirmSMSVerification(
        with code: String,
        with apiClient: STPAPIClient = STPAPIClient.shared,
        cookieStore: LinkCookieStore = LinkSecureCookieStore.shared,
        consumerAccountPublishableKey: String?,
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        apiClient.confirmSMSVerification(
            for: clientSecret,
            with: code,
            cookieStore: cookieStore,
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
