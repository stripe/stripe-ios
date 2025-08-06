//
//  STPAPIClient+CryptoOnramp.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/17/25.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentSheet

// Please do not attempt to modify the Stripe SDK or call private APIs directly.
// See the Stripe Services Agreement (https://stripe.com/legal/ssa) for more details.
extension STPAPIClient {

    /// Errors that can occur that are specific to usage of crypto endpoints.
    enum CryptoOnrampAPIError: Error {

        /// No consumer session client secret was found to be associated with the active link account session.
        case missingConsumerSessionClientSecret

        /// The request requires a session with a verified link account, but the account was found to not be verified.
        case linkAccountNotVerified
    }

    /// Creates a crypto customer on the backend, upon granting the partner-merchant permission to facilitate crypto onramp transactions upon a customer’s behalf.
    /// - Parameter linkAccountInfo: Information associated with the link account including the client secret and whether the account has been verified.
    /// Throws if `linkAccountSessionState` is not verified, a client secret doesn’t exist, or if an API error occurs.
    func grantPartnerMerchantPermissions(with linkAccountInfo: PaymentSheetLinkAccountInfoProtocol) async throws -> CustomerResponse {
        guard let consumerSessionClientSecret = linkAccountInfo.consumerSessionClientSecret else {
            throw CryptoOnrampAPIError.missingConsumerSessionClientSecret
        }

        try validateSessionState(using: linkAccountInfo)

        guard case .verified = linkAccountInfo.sessionState else {
            throw CryptoOnrampAPIError.linkAccountNotVerified
        }

        let endpoint = "crypto/internal/customers"
        let requestObject = CustomerRequest(consumerSessionClientSecret: consumerSessionClientSecret)
        return try await withCheckedThrowingContinuation { continuation in
            post(resource: endpoint, object: requestObject) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Attaches the specific KYC info to the current Link user on the backend.
    /// - Parameters:
    ///   - info: The collected customer information.
    ///   - linkAccountInfo: Information associated with the link account including the client secret and whether the account has been verified.
    ///   - calendar: The calendar to use to convert the user’s date of birth (`KycInfo.dateOfBirth`) to components compatible with the API. Defaults to `calendar.current`.
    /// - Returns: A response object containing the user’s identifier.
    /// Throws if `linkAccountSessionState` is not verified, a client secret doesn’t exist, or if an API error occurs.
    @discardableResult
    func collectKycInfo(info: KycInfo, linkAccountInfo: PaymentSheetLinkAccountInfoProtocol, calendar: Calendar = .current) async throws -> KYCDataCollectionResponse {
        guard let consumerSessionClientSecret = linkAccountInfo.consumerSessionClientSecret else {
            throw CryptoOnrampAPIError.missingConsumerSessionClientSecret
        }

        try validateSessionState(using: linkAccountInfo)

        let endpoint = "crypto/internal/kyc_data_collection"
        let requestObject = KYCDataCollectionRequest(
            credentials: Credentials(consumerSessionClientSecret: consumerSessionClientSecret),
            kycInfo: info,
            calendar: calendar
        )

        return try await withCheckedThrowingContinuation { continuation in
            post(resource: endpoint, object: requestObject) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Begins an identity verification session, providing the necessary data used to initialize the Identity SDK.
    /// - Parameter linkAccountInfo: Information associated with the link account including the client secret and whether the account has been verified.
    /// - Returns: API response that includes information used to initialize the Identity SDK.
    func startIdentityVerification(linkAccountInfo: PaymentSheetLinkAccountInfoProtocol) async throws -> StartIdentityVerificationResponse {
        guard let consumerSessionClientSecret = linkAccountInfo.consumerSessionClientSecret else {
            throw CryptoOnrampAPIError.missingConsumerSessionClientSecret
        }

        try validateSessionState(using: linkAccountInfo)

        let endpoint = "crypto/internal/start_identity_verification"
        let requestObject = StartIdentityVerificationRequest(
            consumerSessionClientSecret: consumerSessionClientSecret
        )

        return try await withCheckedThrowingContinuation { continuation in
            post(resource: endpoint, object: requestObject) { result in
                continuation.resume(with: result)
            }
        }
    }

    private func validateSessionState(using linkAccountInfo: PaymentSheetLinkAccountInfoProtocol) throws {
        guard case .verified = linkAccountInfo.sessionState else {
            throw CryptoOnrampAPIError.linkAccountNotVerified
        }
    }
}
