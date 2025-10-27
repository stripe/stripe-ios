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
    @_spi(STP)
    public enum CryptoOnrampAPIError: LocalizedError {

        /// No consumer session client secret was found to be associated with the active link account session.
        case missingConsumerSessionClientSecret

        /// The request requires a session with a verified link account, but the account was found to not be verified.
        case linkAccountNotVerified

        @_spi(STP)
        public var errorDescription: String? {
            switch self {
            case .missingConsumerSessionClientSecret:
                return "No consumer session client secret was found to be associated with the active link account session."
            case .linkAccountNotVerified:
                return "The request requires a session with a verified link account, but the account was found to not be verified."
            }
        }
    }

    /// Creates a crypto customer on the backend, upon granting the partner-merchant permission to facilitate crypto onramp transactions upon a customer’s behalf.
    /// - Parameter linkAccountInfo: Information associated with the link account including the client secret and whether the account has been verified.
    /// Throws if `linkAccountSessionState` is not verified, a client secret doesn’t exist, or if an API error occurs.
    func createCryptoCustomer(with linkAccountInfo: PaymentSheetLinkAccountInfoProtocol) async throws -> CustomerResponse {
        guard let consumerSessionClientSecret = linkAccountInfo.consumerSessionClientSecret else {
            throw CryptoOnrampAPIError.missingConsumerSessionClientSecret
        }

        try validateSessionState(using: linkAccountInfo)

        let endpoint = "crypto/internal/customers"
        let requestObject = CustomerRequest(consumerSessionClientSecret: consumerSessionClientSecret)
        return try await post(resource: endpoint, object: requestObject)
    }

    /// Attaches the specific KYC info to the current Link user on the backend.
    /// - Parameters:
    ///   - info: The collected customer information.
    ///   - linkAccountInfo: Information associated with the link account including the client secret and whether the account has been verified.
    /// - Returns: A response object containing the user’s identifier.
    /// Throws if `linkAccountSessionState` is not verified, a client secret doesn’t exist, or if an API error occurs.
    @discardableResult
    func collectKycInfo(info: KycInfo, linkAccountInfo: PaymentSheetLinkAccountInfoProtocol) async throws -> KYCDataCollectionResponse {
        guard let consumerSessionClientSecret = linkAccountInfo.consumerSessionClientSecret else {
            throw CryptoOnrampAPIError.missingConsumerSessionClientSecret
        }

        try validateSessionState(using: linkAccountInfo)

        let endpoint = "crypto/internal/kyc_data_collection"
        let requestObject = KYCDataCollectionRequest(
            credentials: Credentials(consumerSessionClientSecret: consumerSessionClientSecret),
            kycInfo: info
        )

        return try await post(resource: endpoint, object: requestObject)
    }

    /// Updates the KYC info for the current Link user on the backend.
    /// - Parameters:
    ///   - info: The collected customer information.
    ///   - linkAccountInfo: Information associated with the link account including the client secret and whether the account has been verified.
    /// - Returns: An empty response
    /// Throws if `linkAccountSessionState` is not verified, a client secret doesn’t exist, or if an API error occurs.
    @discardableResult
    func refreshKycInfo(info: KycRefreshInfo, linkAccountInfo: PaymentSheetLinkAccountInfoProtocol) async throws -> EmptyResponse {
        guard let consumerSessionClientSecret = linkAccountInfo.consumerSessionClientSecret else {
            throw CryptoOnrampAPIError.missingConsumerSessionClientSecret
        }

        try validateSessionState(using: linkAccountInfo)

        let endpoint = "crypto/internal/refresh_consumer_person"
        let requestObject = KYCRefreshRequest(
            credentials: Credentials(consumerSessionClientSecret: consumerSessionClientSecret),
            kycInfo: info
        )

        return try await post(resource: endpoint, object: requestObject)
    }

    /// Retrieves existing KYC info for the current Link user.
    /// - Parameters:
    ///   - linkAccountInfo: Information associated with the link account including the client secret and whether the account has been verified.
    /// - Returns: An instance of `RetrieveKYCInfoResponse` containing the information stored for the user.
    /// Throws if the `linkAccountSessionState` is not verified, a client secret doesn’t exist, or if an API error occurs.
    func retrieveKycInfo(linkAccountInfo: PaymentSheetLinkAccountInfoProtocol) async throws -> RetrieveKYCInfoResponse {
        guard let consumerSessionClientSecret = linkAccountInfo.consumerSessionClientSecret else {
            throw CryptoOnrampAPIError.missingConsumerSessionClientSecret
        }

        try validateSessionState(using: linkAccountInfo)

        let endpoint = "crypto/internal/kyc_data_retrieve"
        let parameters = ["credentials": ["consumer_session_client_secret": consumerSessionClientSecret]]
        return try await get(resource: endpoint, parameters: parameters)
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

    /// Retrieves an onramp session.
    /// - Parameters:
    ///   - sessionId: The onramp session identifier.
    ///   - sessionClientSecret: The onramp session client secret.
    /// - Returns: The onramp session details.
    func getOnrampSession(
        sessionId: String,
        sessionClientSecret: String
    ) async throws -> OnrampSessionResponse {
        let endpoint = "crypto/internal/onramp_session"
        let parameters = ["crypto_onramp_session": sessionId, "client_secret": sessionClientSecret]
        return try await get(resource: endpoint, parameters: parameters)
    }

    /// Creates a crypto payment token from a given payment method and consumer.
    /// - Parameters:
    ///   - paymentMethodId: The originating payment method ID.
    ///   - cryptoCustomerId: The crypto customer ID.
    /// - Returns: The created crypto payment token.
    /// Throws if an API error occurs.
    func createPaymentToken(
        for paymentMethodId: String,
        cryptoCustomerId: String
    ) async throws -> CreatePaymentTokenResponse {
        let endpoint = "crypto/internal/payment_token"
        let requestObject = CreatePaymentTokenRequest(
            paymentMethod: paymentMethodId,
            cryptoCustomerId: cryptoCustomerId
        )
        return try await post(resource: endpoint, object: requestObject)
    }

    /// Retrieves platform settings for the crypto onramp service.
    /// - Parameter cryptoCustomerId: The ID for the crypto customer.
    /// - Returns: Platform settings including the publishable key.
    /// Throws if an API error occurs.
    func getPlatformSettings(
        cryptoCustomerId: String
    ) async throws -> PlatformSettingsResponse {
        let endpoint = "crypto/internal/platform_settings"

        let parameters: [String: Any] = [
            "crypto_customer_id": cryptoCustomerId
        ]
        return try await get(resource: endpoint, parameters: parameters)
    }

    private func postKycInfo<Response: Decodable>(info: KycInfo, linkAccountInfo: PaymentSheetLinkAccountInfoProtocol, isRefresh: Bool) async throws -> Response {
        guard let consumerSessionClientSecret = linkAccountInfo.consumerSessionClientSecret else {
            throw CryptoOnrampAPIError.missingConsumerSessionClientSecret
        }

        try validateSessionState(using: linkAccountInfo)

        let endpoint = isRefresh ? "crypto/internal/refresh_consumer_person" : "crypto/internal/kyc_data_collection"
        let requestObject = KYCDataCollectionRequest(
            credentials: Credentials(consumerSessionClientSecret: consumerSessionClientSecret),
            kycInfo: info
        )

        return try await post(resource: endpoint, object: requestObject)
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
