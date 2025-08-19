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
        return try await post(resource: endpoint, object: requestObject)
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

        return try await post(resource: endpoint, object: requestObject)
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

        return try await post(resource: endpoint, object: requestObject)
    }

    /// Registers the given crypto wallet address to the current Link account.
    /// - Parameters:
    ///   - linkAccountInfo: Information associated with the link account including the client secret and whether the account has been verified.
    ///   - walletAddress: The crypto wallet address to register.
    ///   - network: The crypto network for the wallet address.
    @discardableResult
    func collectWalletAddress(
        walletAddress: String,
        network: CryptoNetwork,
        linkAccountInfo: PaymentSheetLinkAccountInfoProtocol
    ) async throws -> RegisterWalletResponse {
        guard let consumerSessionClientSecret = linkAccountInfo.consumerSessionClientSecret else {
            throw CryptoOnrampAPIError.missingConsumerSessionClientSecret
        }

        try validateSessionState(using: linkAccountInfo)

        let endpoint = "crypto/internal/wallet"
        let requestObject = RegisterWalletRequest(
            walletAddress: walletAddress,
            network: network,
            consumerSessionClientSecret: consumerSessionClientSecret
        )

        return try await post(resource: endpoint, object: requestObject)
    }

    /// Retrieves the PaymentIntent from an onramp session.
    /// - Parameters:
    ///   - sessionId: The onramp session identifier.
    ///   - sessionClientSecret: The onramp session client secret.
    /// - Returns: The PaymentIntent associated with the onramp session.
    func retrievePaymentIntentFromOnrampSession(
        sessionId: String,
        sessionClientSecret: String
    ) async throws -> STPPaymentIntent {
        let endpoint = "crypto/internal/onramp_session"
        let parameters = ["crypto_onramp_session": sessionId, "client_secret": sessionClientSecret]
        return try await APIRequest<STPPaymentIntent>.getWith(self, endpoint: endpoint, parameters: parameters)
    }

    func createPaymentToken(for paymentMethodId: String, linkAccountInfo: PaymentSheetLinkAccountInfoProtocol) async throws -> CreatePaymentTokenResponse {
        // TODO: incorporate the implementation found at https://github.com/stripe/stripe-ios/pull/5302 once merged.
        return CreatePaymentTokenResponse(id: "todo_123")
    }

    /// Retrieves platform settings for the crypto onramp service.
    /// - Returns: Platform settings including the publishable key.
    /// Throws if an API error occurs.
    func getPlatformSettings() async throws -> PlatformSettingsResponse {
        let endpoint = "crypto/internal/platform_settings"
        return try await get(resource: endpoint)
    }

    private func validateSessionState(using linkAccountInfo: PaymentSheetLinkAccountInfoProtocol) throws {
        guard case .verified = linkAccountInfo.sessionState else {
            throw CryptoOnrampAPIError.linkAccountNotVerified
        }
    }
}

private extension STPAPIClient {
    /// Helper method to wrap the closure-based post method for Swift concurrency.
    func post<T: Decodable>(resource: String, object: Encodable) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            post(resource: resource, object: object) { (result: Result<T, Error>) in
                continuation.resume(with: result)
            }
        }
    }

    /// Helper method to wrap the closure-based get method for Swift concurrency.
    func get<T: Decodable>(resource: String, parameters: [String: Any] = [:]) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            get(resource: resource, parameters: parameters) { (result: Result<T, Error>) in
                continuation.resume(with: result)
            }
        }
    }
}
