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

        /// The request requires a session with a verified link account, but the account was found to not be verified.
        case linkAccountNotVerified
    }

    /// Creates a crypto customer on the backend, upon granting the partner-merchant permission to facilitate crypto onramp transactions upon a customer’s behalf.
    /// - Parameter consumerSessionClientSecret: The client secret provided by the Link account’s consumer session.
    /// - Parameter linkAccountSessionState: The current state of the link account, provided by `PaymentSheetLinkAccount.sessionState`.
    /// Throws if `linkAccountSessionState` is not verified, or if an API error occurs.
    func grantPartnerMerchantPermissions(consumerSessionClientSecret: String, linkAccountSessionState: PaymentSheetLinkAccount.SessionState) async throws -> CustomerResponse {
        switch linkAccountSessionState {
        case .verified:
            break
        case .requiresSignUp, .requiresVerification:
            throw CryptoOnrampAPIError.linkAccountNotVerified
        @unknown default:
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
}
