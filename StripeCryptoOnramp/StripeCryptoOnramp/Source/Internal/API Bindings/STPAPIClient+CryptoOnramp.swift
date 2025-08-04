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

        guard case .verified = linkAccountInfo.sessionState else {
            throw CryptoOnrampAPIError.linkAccountNotVerified
        }

        let endpoint = "crypto/internal/customers"
        let requestObject = CustomerRequest(consumerSessionClientSecret: consumerSessionClientSecret)
        return try await withCheckedThrowingContinuation { continuation in
            post(resource: endpoint, object: requestObject) { (result: Result<CustomerResponse, Error>) in
                switch result {
                case .success(let customer):
                    continuation.resume(returning: customer)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func collectKYCData(_ kycData: KYCData) async throws {

    }
}
