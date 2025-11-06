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
@_spi(STP) import StripeUICore

/// For internal SDK use only
final class ConsumerSession: Decodable {
    let clientSecret: String
    let emailAddress: String
    let redactedFormattedPhoneNumber: String
    let unredactedPhoneNumber: String?
    let phoneNumberCountry: String?
    let verificationSessions: [VerificationSession]
    let supportedPaymentDetailsTypes: Set<ConsumerPaymentDetails.DetailsType>
    let mobileFallbackWebviewParams: MobileFallbackWebviewParams?

    init(
        clientSecret: String,
        emailAddress: String,
        redactedFormattedPhoneNumber: String,
        unredactedPhoneNumber: String?,
        phoneNumberCountry: String?,
        verificationSessions: [VerificationSession],
        supportedPaymentDetailsTypes: Set<ConsumerPaymentDetails.DetailsType>,
        mobileFallbackWebviewParams: MobileFallbackWebviewParams?
    ) {
        self.clientSecret = clientSecret
        self.emailAddress = emailAddress
        self.redactedFormattedPhoneNumber = redactedFormattedPhoneNumber
        self.unredactedPhoneNumber = unredactedPhoneNumber
        self.phoneNumberCountry = phoneNumberCountry
        self.verificationSessions = verificationSessions
        self.supportedPaymentDetailsTypes = supportedPaymentDetailsTypes
        self.mobileFallbackWebviewParams = mobileFallbackWebviewParams
    }

    private enum CodingKeys: String, CodingKey {
        case clientSecret
        case emailAddress
        case redactedFormattedPhoneNumber
        case unredactedPhoneNumber
        case phoneNumberCountry
        case verificationSessions
        case supportedPaymentDetailsTypes = "supportPaymentDetailsTypes"
        case mobileFallbackWebviewParams = "mobile_fallback_webview_params"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.clientSecret = try container.decode(String.self, forKey: .clientSecret)
        self.emailAddress = try container.decode(String.self, forKey: .emailAddress)
        self.redactedFormattedPhoneNumber = try container.decode(String.self, forKey: .redactedFormattedPhoneNumber)
        self.unredactedPhoneNumber = try container.decodeIfPresent(String.self, forKey: .unredactedPhoneNumber)
        self.phoneNumberCountry = try container.decodeIfPresent(String.self, forKey: .phoneNumberCountry)
        self.verificationSessions = try container.decodeIfPresent([ConsumerSession.VerificationSession].self, forKey: .verificationSessions) ?? []
        self.supportedPaymentDetailsTypes = try container.decodeIfPresent(Set<ConsumerPaymentDetails.DetailsType>.self, forKey: .supportedPaymentDetailsTypes) ?? []
        self.mobileFallbackWebviewParams = try container.decodeIfPresent(MobileFallbackWebviewParams.self, forKey: .mobileFallbackWebviewParams)
    }

}

extension ConsumerSession {
    struct MobileFallbackWebviewParams: Decodable {
        let webviewOpenUrl: URL?
        let webviewRequirementType: WebviewRequirementType

        enum WebviewRequirementType: String, SafeEnumDecodable {
            case required = "required"
            case notRequired = "notrequired"
            case unparsable
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let requirementType = try container.decode(WebviewRequirementType.self, forKey: .webviewRequirementType)
            self.webviewRequirementType = requirementType

            if let urlString = try container.decodeIfPresent(String.self, forKey: .webviewOpenUrl) {
                self.webviewOpenUrl = URL(string: urlString)
            } else {
                self.webviewOpenUrl = nil
            }
        }

        private enum CodingKeys: String, CodingKey {
            case webviewOpenUrl = "webview_open_url"
            case webviewRequirementType = "webview_requirement_type"
        }
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

    var isVerifiedWithLinkAuthToken: Bool {
        verificationSessions.containsVerifiedLinkAuthTokenSession
    }

    var hasStartedSMSVerification: Bool {
        verificationSessions.contains( where: { $0.type == .sms && $0.state == .started })
    }

    var isVerifiedForSignup: Bool {
        verificationSessions.isVerifiedForSignup
    }

    /// Returns the unredacted phone number with the appropriate country code, if available.
    /// Example value: `+15551236789`
    var unredactedPhoneNumberWithPrefix: String? {
        guard let unredactedPhoneNumber else {
            return nil
        }
        return PhoneNumber(number: unredactedPhoneNumber, countryCode: phoneNumberCountry)?.string(as: .e164)
    }
}

// MARK: - API methods
extension ConsumerSession {
    class func lookupSession(
        for email: String?,
        emailSource: EmailSource?,
        sessionID: String,
        customerID: String?,
        with apiClient: STPAPIClient = STPAPIClient.shared,
        useMobileEndpoints: Bool,
        canSyncAttestationState: Bool,
        doNotLogConsumerFunnelEvent: Bool,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ConsumerSession.LookupResponse, Error>) -> Void
    ) {
        apiClient.lookupConsumerSession(
            for: email,
            emailSource: emailSource,
            sessionID: sessionID,
            customerID: customerID,
            useMobileEndpoints: useMobileEndpoints,
            canSyncAttestationState: canSyncAttestationState,
            doNotLogConsumerFunnelEvent: doNotLogConsumerFunnelEvent,
            requestSurface: requestSurface,
            completion: completion
        )
    }

    class func lookupLinkAuthToken(
        _ linkAuthTokenClientSecret: String,
        sessionID: String,
        customerID: String?,
        with apiClient: STPAPIClient = STPAPIClient.shared,
        useMobileEndpoints: Bool,
        canSyncAttestationState: Bool,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ConsumerSession.LookupResponse, Error>) -> Void
    ) {
        apiClient.lookupLinkAuthToken(
            linkAuthTokenClientSecret,
            sessionID: sessionID,
            customerID: customerID,
            useMobileEndpoints: useMobileEndpoints,
            canSyncAttestationState: canSyncAttestationState,
            requestSurface: requestSurface,
            completion: completion
        )
    }

    class func lookupLinkAuthIntent(
        linkAuthIntentID: String,
        sessionID: String,
        customerID: String?,
        with apiClient: STPAPIClient = STPAPIClient.shared,
        useMobileEndpoints: Bool,
        canSyncAttestationState: Bool,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ConsumerSession.LookupResponse, Error>) -> Void
    ) {
        apiClient.lookupLinkAuthIntent(
            linkAuthIntentID: linkAuthIntentID,
            sessionID: sessionID,
            customerID: customerID,
            useMobileEndpoints: useMobileEndpoints,
            canSyncAttestationState: canSyncAttestationState,
            requestSurface: requestSurface,
            completion: completion
        )
    }

    class func signUp(
        email: String,
        phoneNumber: String?,
        locale: Locale = .autoupdatingCurrent,
        legalName: String?,
        countryCode: String?,
        consentAction: String?,
        useMobileEndpoints: Bool,
        canSyncAttestationState: Bool,
        with apiClient: STPAPIClient = STPAPIClient.shared,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<SessionWithPublishableKey, Error>) -> Void
    ) {
        apiClient.createConsumer(
            for: email,
            with: phoneNumber,
            locale: locale,
            legalName: legalName,
            countryCode: countryCode,
            consentAction: consentAction,
            useMobileEndpoints: useMobileEndpoints,
            canSyncAttestationState: canSyncAttestationState,
            requestSurface: requestSurface,
            completion: completion
        )
    }

    func createPaymentDetails(
        paymentMethodParams: STPPaymentMethodParams,
        with apiClient: STPAPIClient = STPAPIClient.shared,
        isDefault: Bool = false,
        requestSurface: LinkRequestSurface = .default,
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

        // This email address needs to be lowercase or the API will reject it
        let billingEmailAddress = (paymentMethodParams.nonnil_billingDetails.email ?? emailAddress).lowercased()

        apiClient.createPaymentDetails(
            for: clientSecret,
            cardParams: cardParams,
            billingEmailAddress: billingEmailAddress,
            billingDetails: paymentMethodParams.nonnil_billingDetails,
            isDefault: isDefault,
            clientAttributionMetadata: paymentMethodParams.clientAttributionMetadata,
            requestSurface: requestSurface,
            completion: completion)
    }

    func createPaymentDetails(
        linkedAccountId: String,
        with apiClient: STPAPIClient = STPAPIClient.shared,
        isDefault: Bool,
        clientAttributionMetadata: STPClientAttributionMetadata?,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        apiClient.createPaymentDetails(
            for: clientSecret,
            linkedAccountId: linkedAccountId,
            isDefault: isDefault,
            clientAttributionMetadata: clientAttributionMetadata,
            requestSurface: requestSurface,
            completion: completion)
    }

    func startVerification(
        type: VerificationSession.SessionType = .sms,
        locale: Locale = .autoupdatingCurrent,
        isResendingSmsCode: Bool = false,
        with apiClient: STPAPIClient = STPAPIClient.shared,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        apiClient.startVerification(
            for: clientSecret,
            type: type,
            locale: locale,
            isResendingSmsCode: isResendingSmsCode,
            requestSurface: requestSurface,
            completion: completion)
    }

    func confirmSMSVerification(
        with code: String,
        with apiClient: STPAPIClient = STPAPIClient.shared,
        requestSurface: LinkRequestSurface = .default,
        consentGranted: Bool? = nil,
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        apiClient.confirmSMSVerification(
            for: clientSecret,
            with: code,
            requestSurface: requestSurface,
            consentGranted: consentGranted,
            completion: completion)
    }

    func createLinkAccountSession(
        with apiClient: STPAPIClient = STPAPIClient.shared,
        linkMode: LinkMode? = nil,
        intentToken: String? = nil,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<LinkAccountSession, Error>) -> Void
    ) {
        apiClient.createLinkAccountSession(
            for: clientSecret,
            linkMode: linkMode,
            intentToken: intentToken,
            requestSurface: requestSurface,
            completion: completion)
    }

    func listPaymentDetails(
        with apiClient: STPAPIClient = STPAPIClient.shared,
        supportedPaymentDetailsTypes: [ConsumerPaymentDetails.DetailsType],
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<[ConsumerPaymentDetails], Error>) -> Void
    ) {
        apiClient.listPaymentDetails(
            for: clientSecret,
            supportedPaymentDetailsTypes: supportedPaymentDetailsTypes,
            requestSurface: requestSurface,
            completion: completion)
    }

    func listShippingAddress(
        with apiClient: STPAPIClient = STPAPIClient.shared,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ShippingAddressesResponse, Error>) -> Void
    ) {
        apiClient.listShippingAddress(
            for: clientSecret,
            requestSurface: requestSurface,
            completion: completion)
    }

    func deletePaymentDetails(
        with apiClient: STPAPIClient = STPAPIClient.shared,
        id: String,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        apiClient.deletePaymentDetails(
            for: clientSecret,
            id: id,
            requestSurface: requestSurface,
            completion: completion)
    }

    func updatePaymentDetails(
        with apiClient: STPAPIClient = STPAPIClient.shared,
        id: String,
        updateParams: UpdatePaymentDetailsParams,
        clientAttributionMetadata: STPClientAttributionMetadata?,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        apiClient.updatePaymentDetails(
            for: clientSecret, id: id,
            updateParams: updateParams,
            clientAttributionMetadata: clientAttributionMetadata,
            requestSurface: requestSurface,
            completion: completion)
    }

    func sharePaymentDetails(
        with apiClient: STPAPIClient = STPAPIClient.shared,
        id: String,
        cvc: String?,
        allowRedisplay: STPPaymentMethodAllowRedisplay?,
        expectedPaymentMethodType: String?,
        billingPhoneNumber: String?,
        clientAttributionMetadata: STPClientAttributionMetadata?,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<PaymentDetailsShareResponse, Error>) -> Void
    ) {
        apiClient.sharePaymentDetails(
            for: clientSecret,
            id: id,
            allowRedisplay: allowRedisplay,
            cvc: cvc,
            expectedPaymentMethodType: expectedPaymentMethodType,
            billingPhoneNumber: billingPhoneNumber,
            clientAttributionMetadata: clientAttributionMetadata,
            requestSurface: requestSurface,
            completion: completion)
    }

    func logout(
        with apiClient: STPAPIClient = STPAPIClient.shared,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        apiClient.logout(
            consumerSessionClientSecret: clientSecret,
            requestSurface: requestSurface,
            completion: completion)
    }

    func refreshSession(
        with apiClient: STPAPIClient = STPAPIClient.shared,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        apiClient.refreshSession(
            consumerSessionClientSecret: clientSecret,
            requestSurface: requestSurface,
            completion: completion
        )
    }

}
