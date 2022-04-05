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
    
    let supportedPaymentDetailsTypes: [ConsumerPaymentDetails.DetailsType]
    
    let allResponseFields: [AnyHashable : Any]

    private init(clientSecret: String,
                 emailAddress: String,
                 redactedPhoneNumber: String,
                 verificationSessions: [VerificationSession],
                 authSessionClientSecret: String?,
                 supportedPaymentDetailsTypes: [ConsumerPaymentDetails.DetailsType],
                 allResponseFields: [AnyHashable : Any]) {
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
              let redactedPhoneNumber = dict["redacted_phone_number"] as? String,
              let supportedPaymentDetailsTypeStrings = dict["support_payment_details_types"] as? [String] else {
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

        let supportedPaymentDetailsTypes: [ConsumerPaymentDetails.DetailsType] =
        supportedPaymentDetailsTypeStrings.compactMap({ ConsumerPaymentDetails.DetailsType(rawValue: $0.lowercased()) })

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
    
    var isVerifiedForSignup: Bool {
        verificationSessions.isVerifiedForSignup
    }
}


// MARK: - API methods
extension ConsumerSession {

    class func lookupSession(for email: String?,
                             with apiClient: STPAPIClient = STPAPIClient.shared,
                             cookieStore: LinkCookieStore = LinkSecureCookieStore.shared,
                             completion: @escaping (ConsumerSession.LookupResponse?, Error?) -> Void) {
        apiClient.lookupConsumerSession(for: email, cookieStore: cookieStore, completion: completion)
    }

    class func signUp(email: String,
                      phoneNumber: String,
                      countryCode: String?,
                      with apiClient: STPAPIClient = STPAPIClient.shared,
                      cookieStore: LinkCookieStore = LinkSecureCookieStore.shared,
                      completion: @escaping (ConsumerSession?, Error?) -> Void) {
        apiClient.createConsumer(
            for: email,
            with: phoneNumber,
            countryCode: countryCode,
            cookieStore: cookieStore,
            completion: completion
        )
    }

    func createPaymentDetails(paymentMethodParams: STPPaymentMethodParams,
                              with apiClient: STPAPIClient = STPAPIClient.shared,
                              completion: @escaping (ConsumerPaymentDetails?, Error?) -> Void) {
        guard paymentMethodParams.type == .card,
              let billingDetails = paymentMethodParams.billingDetails,
              let cardParams = paymentMethodParams.card else {
            DispatchQueue.main.async {
                assertionFailure()
                completion(nil, NSError.stp_genericConnectionError())
            }
            return
        }

        apiClient.createPaymentDetails(
            for: clientSecret,
            cardParams: cardParams,
            billingDetails: billingDetails,
            completion: completion)

    }

    func createPaymentDetails(linkedAccountId: String,
                              with apiClient: STPAPIClient = STPAPIClient.shared,
                              completion: @escaping (ConsumerPaymentDetails?, Error?) -> Void) {

        apiClient.createPaymentDetails(
            for: clientSecret,
            linkedAccountId: linkedAccountId,
            completion: completion)

    }

    func startVerification(type: VerificationSession.SessionType = .sms,
                           locale: String = Locale.autoupdatingCurrent.identifier,
                           with apiClient: STPAPIClient = STPAPIClient.shared,
                           cookieStore: LinkCookieStore = LinkSecureCookieStore.shared,
                           completion: @escaping (ConsumerSession?, Error?) -> Void) {
        apiClient.startVerification(for: clientSecret,
                                    type: type,
                                    locale: locale,
                                    cookieStore: cookieStore,
                                    completion: completion)
    }

    func confirmSMSVerification(with code: String,
                                with apiClient: STPAPIClient = STPAPIClient.shared,
                                cookieStore: LinkCookieStore = LinkSecureCookieStore.shared,
                                completion:  @escaping (ConsumerSession?, Error?) -> Void) {
        apiClient.confirmSMSVerification(for: clientSecret,
                                         with: code,
                                         cookieStore: cookieStore,
                                         completion: completion)
    }
    
    func createLinkAccountSession(with apiClient: STPAPIClient = STPAPIClient.shared,
                                  successURL: String,
                                  cancelURL: String,
                                  completion: @escaping (LinkAccountSession?, Error?) -> Void) {
        apiClient.createLinkAccountSession(for: clientSecret,
                                           successURL: successURL,
                                           cancelURL: cancelURL,
                                              completion:completion)
    }
    
    func attachAsAccountHolder(to linkAccountSessionClientSecret: String,
                               with apiClient: STPAPIClient = STPAPIClient.shared,
                               completion: @escaping (LinkAccountSessionAttachResponse?, Error?) -> Void) {
        apiClient.attachAccountHolder(to: linkAccountSessionClientSecret,
                                      consumerSessionClientSecret: clientSecret,
                                      completion: completion)
    }

    func listPaymentDetails(with apiClient: STPAPIClient = STPAPIClient.shared,
                            completion: @escaping ([ConsumerPaymentDetails]?, Error?) -> Void) {
        apiClient.listPaymentDetails(for: clientSecret,
                                     completion: completion)
    }

    func deletePaymentDetails(with apiClient: STPAPIClient = STPAPIClient.shared,
                             id: String,
                             completion: @escaping (STPEmptyStripeResponse?, Error?) -> Void) {
        apiClient.deletePaymentDetails(for: clientSecret, id: id, completion: completion)
    }

    func updatePaymentDetails(with apiClient: STPAPIClient = STPAPIClient.shared,
                              id: String,
                              updateParams: UpdatePaymentDetailsParams,
                              completion: @escaping (ConsumerPaymentDetails?, Error?) -> Void) {
        apiClient.updatePaymentDetails(
            for: clientSecret, id: id,
               updateParams: updateParams,
               completion: completion)
    }

    func logout(
        with apiClient: STPAPIClient = STPAPIClient.shared,
        cookieStore: LinkCookieStore = LinkSecureCookieStore.shared,
        completion: @escaping (ConsumerSession?, Error?) -> Void
    ) {
        // Logout from server.
        apiClient.logout(
            consumerSessionClientSecret: clientSecret,
            cookieStore: cookieStore,
            completion: completion)
    }

}
