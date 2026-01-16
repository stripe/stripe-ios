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
    /// - Parameter checkoutSessionId: The ID of the checkout session (e.g., "cs_test_xxx")
    /// - Returns: CheckoutSessionInitResponse containing the session and elements session
    func initCheckoutSession(checkoutSessionId: String) async throws -> CheckoutSessionInitResponse {
        let parameters: [String: Any] = [
            "browser_locale": Locale.current.toLanguageTag(),
            "browser_timezone": TimeZone.current.identifier,
            "eid": UUID().uuidString,
            "redirect_type": "embedded",
            "elements_session_client": [
                "is_aggregation_expected": true,
            ],
        ]

        let checkoutSession: STPCheckoutSession = try await APIRequest<STPCheckoutSession>.post(
            with: self,
            endpoint: "payment_pages/\(checkoutSessionId)/init",
            parameters: parameters
        )

        guard let elementsSessionJSON = checkoutSession.allResponseFields["elements_session"] as? [AnyHashable: Any],
              let elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJSON) else {
            throw PaymentSheetError.unknown(debugDescription: "Failed to decode elements session from checkout session init response")
        }

        return CheckoutSessionInitResponse(
            checkoutSession: checkoutSession,
            elementsSession: elementsSession
        )
    }
}
