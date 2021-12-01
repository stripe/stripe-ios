//
//  StripeAPIError.swift
//  StripeCore
//
//  Created by David Estes on 8/11/21.
//

import Foundation

/// An error returned from the Stripe API.
/// https://stripe.com/docs/api/errors
struct StripeAPIError: StripeDecodable {
    /// The type of error returned.
    var type: ErrorType
    /// For some errors that could be handled programmatically, a short string indicating the error code reported.
    /// https://stripe.com/docs/error-codes
    var code: String?
    /// A URL to more information about the error code reported.
    var docUrl: URL?
    /// A human-readable message providing more details about the error. For card errors, these messages can be shown to your users.
    var message: String?
    /// If the error is parameter-specific, the parameter related to the error. For example, you can use this to display a message near the correct form field.
    var param: String?
    
    // More information may be available in `allResponseFields`, including
    // the PaymentIntent or PaymentMethod.

    /// Types of errors presented by the API.
    enum ErrorType: String, Decodable {
        case apiError = "api_error"
        case cardError = "card_error"
        case idempotencyError = "idempotency_error"
        case invalidRequestError = "invalid_request_error"
    }
    
    var _allResponseFieldsStorage: NonEncodableParameters?
}

struct StripeAPIErrorResponse: StripeDecodable {
    @IncludeUnknownFields
    var error: StripeAPIError?

    var _allResponseFieldsStorage: NonEncodableParameters?
}

extension NSError {
    static func stp_error(from stripeApiError: StripeAPIError) -> NSError? {
        return stp_error(
            errorType: stripeApiError.type.rawValue,
            stripeErrorCode: stripeApiError.code,
            stripeErrorMessage: stripeApiError.message,
            errorParam: stripeApiError.param,
            declineCode: nil,
            httpResponse: nil
        )
    }
}

extension StripeAPIError {
    func errorUserInfoString(key: String) -> String? {
        return NSError.stp_error(from: self)?.userInfo[key] as? String
    }
}
