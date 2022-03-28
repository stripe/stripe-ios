//
//  LinkAccountSession.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 7/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeCore

@_spi(STP) import StripeUICore

protocol PaymentSheetLinkAccountInfoProtocol {
    var email: String { get }
    var redactedPhoneNumber: String? { get }
    var isRegistered: Bool { get }
}

class PaymentSheetLinkAccount: PaymentSheetLinkAccountInfoProtocol {

    enum SessionState {
        case requiresSignUp
        case requiresVerification
        case verified
    }

    // Dependencies
    let apiClient: STPAPIClient
    let cookieStore: LinkCookieStore
    
    let email: String
    
    var redactedPhoneNumber: String? {
        return currentSession?.redactedPhoneNumber
    }
    
    var isRegistered: Bool {
        return currentSession != nil
    }

    var sessionState: SessionState {
        if let currentSession = currentSession {
            // sms verification is not required if we are in the signup flow
            return currentSession.hasVerifiedSMSSession || currentSession.isVerifiedForSignup ? .verified : .requiresVerification
        } else {
            return .requiresSignUp
        }
    }

    var hasStartedSMSVerification: Bool {
        return currentSession?.verificationSessions.contains( where: { $0.type == .sms && $0.state == .started }) ?? false
    }
    
    var supportedPaymentMethodTypes: [STPPaymentMethodType] {
        guard let currentSession = currentSession else {
            return []
        }
        
        var supportedPaymentMethodTypes = [STPPaymentMethodType]()
        for paymentDetailsType in currentSession.supportedPaymentDetailsTypes {
            switch paymentDetailsType {
            case .card:
                supportedPaymentMethodTypes.append(.card)
            case .bankAccount:
                // TODO(ramont): Re-enable after API update.
                // supportedPaymentMethodTypes.append(.linkInstantDebit)
                break
            }
        }
        
        return supportedPaymentMethodTypes
    }

    private var currentSession: ConsumerSession? = nil

    init(
        email: String,
        session: ConsumerSession?,
        apiClient: STPAPIClient = .shared,
        cookieStore: LinkCookieStore = LinkSecureCookieStore.shared
    ) {
        self.email = email
        self.currentSession = session
        self.apiClient = apiClient
        self.cookieStore = cookieStore
    }
    
    func signUp(with phoneNumber: PhoneNumber, completion: @escaping (Result<Void, Error>) -> Void) {
        signUp(with: phoneNumber.string(as: .e164), countryCode: phoneNumber.countryCode, completion: completion)
    }
    
    func signUp(
        with phoneNumber: String,
        countryCode: String?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard case .requiresSignUp = sessionState else {
            assertionFailure()
            DispatchQueue.main.async {
                completion(.failure(
                    PaymentSheetError.unknown(debugDescription: "Don't call sign up if not needed")
                ))
            }
            return
        }

        ConsumerSession.signUp(
            email: email,
            phoneNumber: phoneNumber,
            countryCode: countryCode,
            with: apiClient,
            cookieStore: cookieStore
        ) { signedUpSession, error in
            if let error = error {
                completion(.failure(error))
            } else {
                self.currentSession = signedUpSession
                completion(.success(()))
            }
        }
    }
    
    func startVerification(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard case .requiresVerification = sessionState else {
            DispatchQueue.main.async {
                completion(.success(false))
            }
            return
        }

        guard let session = currentSession else {
            assertionFailure()
            DispatchQueue.main.async {
                completion(.failure(
                    PaymentSheetError.unknown(debugDescription: "Don't call verify if not needed")
                ))
            }
            return
        }

        session.startVerification(with: apiClient, cookieStore: cookieStore) { startVerificationSession, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            self.currentSession = startVerificationSession
            completion(.success(self.hasStartedSMSVerification))
        }
    }
    
    func verify(with oneTimePasscode: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard case .requiresVerification = sessionState,
              hasStartedSMSVerification,
              let session = currentSession else {
            assertionFailure()
            DispatchQueue.main.async {
                completion(.failure(
                    PaymentSheetError.unknown(debugDescription: "Don't call verify if not needed")
                ))
            }
            return
        }

        session.confirmSMSVerification(
            with: oneTimePasscode,
            with: apiClient,
            cookieStore: cookieStore
        ) { verifiedSession, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            self.currentSession = verifiedSession

            completion(.success(()))
        }
    }
    
    func createlinkAccountSession(successURL: String,
                                 cancelURL: String,
                                 completion: @escaping (LinkAccountSession?, Error?) -> Void) {
        guard let consumerSession = currentSession else {
            assertionFailure()
            completion(nil, PaymentSheetError.unknown(debugDescription: "Linking account session without valid consumer session"))
            return
        }
        consumerSession.createLinkAccountSession(successURL: successURL, cancelURL: cancelURL, completion: completion)
    }
    
    func attachAsAccountHolder(to linkAccountSessionClientSecret: String,
                               completion: @escaping (LinkAccountSessionAttachResponse?, Error?) -> Void) {
        guard let consumerSession = currentSession,
              consumerSession.hasVerifiedSMSSession else {
            assertionFailure()
            completion(nil, PaymentSheetError.unknown(debugDescription: "Attaching to link account session without valid consumer session"))
            return
        }
        consumerSession.attachAsAccountHolder(to: linkAccountSessionClientSecret, completion: completion)
    }
    
    func createPaymentDetails(with paymentMethodParams: STPPaymentMethodParams, completion: @escaping (ConsumerPaymentDetails?, Error?)->Void) {
        guard let consumerSession = currentSession else {
            assertionFailure()
            completion(nil, PaymentSheetError.unknown(debugDescription: "Saving to Link without valid session"))
            return
        }

        consumerSession.createPaymentDetails(
            paymentMethodParams: paymentMethodParams,
            with: apiClient,
            completion: completion
        )
    }
    
    func createPaymentDetails(linkedAccountId: String,
                              completion: @escaping (ConsumerPaymentDetails?, Error?) -> Void) {
        guard let consumerSession = currentSession else {
            assertionFailure()
            completion(nil, PaymentSheetError.unknown(debugDescription: "Saving to Link without valid session"))
            return
        }
        consumerSession.createPaymentDetails(linkedAccountId: linkedAccountId, completion: completion)
    }
    
    func listPaymentDetails(completion: @escaping ([ConsumerPaymentDetails]?, Error?) -> Void) {
        guard let consumerSession = currentSession else {
            assertionFailure()
            completion(nil, PaymentSheetError.unknown(debugDescription: "Paying with Link without valid session"))
            return
        }

        consumerSession.listPaymentDetails(with: apiClient, completion: completion)
    }

    func deletePaymentDetails(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let session = currentSession else {
            assertionFailure()
            return completion(.failure(PaymentSheetError.unknown(
                debugDescription: "Deleting Link payment details without valid session")
            ))
        }

        session.deletePaymentDetails(with: apiClient, id: id) { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func updatePaymentDetails(
        id: String,
        updateParams: UpdatePaymentDetailsParams,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        guard let session = currentSession else {
            assertionFailure()
            return completion(.failure(PaymentSheetError.unknown(
                debugDescription: "Updating Link payment details without valid session")
            ))
        }

        session.updatePaymentDetails(with: apiClient, id: id, updateParams: updateParams) { paymentDetails, error in
            if let error = error {
                return completion(.failure(error))
            }

            if let paymentDetails = paymentDetails {
                return completion(.success(paymentDetails))
            }
        }
    }

    func logout(completion: (() -> Void)? = nil) {
        guard let session = currentSession else {
            assertionFailure("Cannot logout without an active session")
            completion?()
            return
        }

        session.logout(with: apiClient, cookieStore: cookieStore) { _, _ in
            completion?()
        }

        // Delete cookie.
        cookieStore.delete(key: cookieStore.sessionCookieKey)
        
        markEmailAsLoggedOut()
        
        // Forget current session.
        self.currentSession = nil
    }

    func markEmailAsLoggedOut() {
        guard let hashedEmail = email.lowercased().sha256 else {
            return
        }

        cookieStore.write(key: cookieStore.emailCookieKey, value: hashedEmail)
    }

}

// MARK: - Payment method params

extension PaymentSheetLinkAccount {

    /// Converts a `ConsumerPaymentDetails` into a `STPPaymentMethodParams` object, injecting
    /// the required Link credentials.
    ///
    /// Returns `nil` if not authenticated/logged in.
    ///
    /// - Parameter paymentDetails: Payment details
    /// - Returns: Payment method params for paying with Link.
    func makePaymentMethodParams(from paymentDetails: ConsumerPaymentDetails) -> STPPaymentMethodParams? {
        guard let currentSession = currentSession else {
            assertionFailure("Cannot make payment method params without an active session.")
            return nil
        }

        let params = STPPaymentMethodParams(type: .link)
        params.link?.paymentDetailsID = paymentDetails.stripeID
        params.link?.credentials = ["consumer_session_client_secret": currentSession.clientSecret]

        if let cvc = paymentDetails.cvc {
            params.link?.additionalAPIParameters["card"] = [
                "cvc": cvc
            ]
        }

        return params
    }

}
