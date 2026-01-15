//
//  STPAPIClient+CheckoutSession.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/15/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// Response wrapper for the checkout session init API.
/// Contains both the checkout session and elements session data.
struct CheckoutSessionInitResponse {
    let checkoutSession: STPCheckoutSession
    let elementsSession: STPElementsSession
}

extension STPAPIClient {

    /// Initializes a CheckoutSession, fetching payment configuration data.
    /// - Parameters:
    ///   - checkoutSessionId: The ID of the checkout session (e.g., "cs_test_xxx")
    ///   - completion: Completion handler with the result containing the session and elements session
    func initCheckoutSession(
        checkoutSessionId: String,
        completion: @escaping (Result<CheckoutSessionInitResponse, Error>) -> Void
    ) {
        let parameters: [String: Any] = [
            "browser_locale": Locale.current.toLanguageTag(),
            "browser_timezone": TimeZone.current.identifier,
            "eid": UUID().uuidString,
            "redirect_type": "embedded",
            "elements_session_client": [
                "is_aggregation_expected": true,
            ],
        ]

        APIRequest<STPCheckoutSession>.post(
            with: self,
            endpoint: "payment_pages/\(checkoutSessionId)/init",
            parameters: parameters
        ) { checkoutSession, _, error in
            guard let checkoutSession else {
                completion(.failure(error ?? PaymentSheetError.unknown(debugDescription: "Failed to init checkout session")))
                return
            }

            guard let elementsSessionJSON = checkoutSession.allResponseFields["elements_session"] as? [AnyHashable: Any],
                  let elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJSON) else {
                completion(.failure(PaymentSheetError.unknown(debugDescription: "Failed to decode elements session from checkout session init response")))
                return
            }

            completion(.success(CheckoutSessionInitResponse(
                checkoutSession: checkoutSession,
                elementsSession: elementsSession
            )))
        }
    }

    /// Initializes a CheckoutSession, fetching payment configuration data.
    /// - Parameter checkoutSessionId: The ID of the checkout session (e.g., "cs_test_xxx")
    /// - Returns: CheckoutSessionInitResponse containing the session and elements session
    func initCheckoutSession(checkoutSessionId: String) async throws -> CheckoutSessionInitResponse {
        try await withCheckedThrowingContinuation { continuation in
            initCheckoutSession(checkoutSessionId: checkoutSessionId) { result in
                continuation.resume(with: result)
            }
        }
    }
}
