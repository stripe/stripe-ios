//
//  StripeServiceError.swift
//  StripeCore
//
//  Created by David Estes on 8/11/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// An error returned from the Stripe API.
///
/// https://stripe.com/docs/api/errors
@_spi(InternalOnlyAPI) public struct StripeAPIError: UnknownFieldsDecodable, Encodable, Equatable {

    /// The type of error returned.
    @_spi(InternalOnlyAPI) public var type: ErrorType
    /// For some errors that could be handled programmatically,
    /// a short string indicating the error code reported.
    ///
    /// https://stripe.com/docs/error-codes
    @_spi(InternalOnlyAPI) public var code: String?
    /// A URL to more information about the error code reported.
    @_spi(InternalOnlyAPI) public var docUrl: URL?
    /// A human-readable message providing more details about the error.
    ///
    /// For card errors, these messages can be shown to your users.
    @_spi(InternalOnlyAPI) public var message: String?
    /// If the error is parameter-specific, the parameter related to the error.
    ///
    /// For example, you can use this to display a message near the correct form field.
    @_spi(InternalOnlyAPI) public var param: String?
    /// The response’s HTTP status code.
    @_spi(InternalOnlyAPI) public var httpStatusCode: Int?
    /// The Stripe API request ID, if available. Looks like `req_123`.
    @_spi(InternalOnlyAPI) public var requestID: String?

    /// Uses the server's optional message instead of the SDK's localized error messages.
    /// Set by Checkout, never encoded or read from an API response.
    @_spi(InternalOnlyAPI) public var useServerErrorMessage = false

    // Set by the API client, never decoded from the response body.
    var includeRequestIDInDescription = false

    // More information may be available in `allResponseFields`, including
    // the PaymentIntent or PaymentMethod.

    /// Types of errors presented by the API.
    @_spi(InternalOnlyAPI) public enum ErrorType: String, SafeEnumCodable {
        case apiError = "api_error"
        case cardError = "card_error"
        case idempotencyError = "idempotency_error"
        case invalidRequestError = "invalid_request_error"
        case unparsable
    }

    public var _allResponseFieldsStorage: NonEncodableParameters?

    // Presentation settings are set by the SDK, never encoded or read from an API response.
    private enum CodingKeys: String, CodingKey {

        case type, code, docUrl, message, param, httpStatusCode, requestID
        case _allResponseFieldsStorage
    }
}

@_spi(InternalOnlyAPI) public struct StripeAPIErrorResponse: UnknownFieldsDecodable {
    @_spi(InternalOnlyAPI) public var error: StripeAPIError?

    public var _allResponseFieldsStorage: NonEncodableParameters?
}

extension NSError {
    static func stp_error(from stripeApiError: StripeAPIError) -> NSError {
        return stp_error(
            errorType: stripeApiError.type.rawValue,
            stripeErrorCode: stripeApiError.code,
            stripeErrorMessage: stripeApiError.message,
            errorParam: stripeApiError.param,
            declineCode: nil,
            intent: nil,
            httpResponse: nil,
            requestID: stripeApiError.requestID,
            includeRequestIDInDescription: stripeApiError.includeRequestIDInDescription,
            useServerErrorMessage: stripeApiError.useServerErrorMessage
        )
    }
}

extension StripeAPIError {
    func errorUserInfoString(key: String) -> String? {
        return NSError.stp_error(from: self).userInfo[key] as? String
    }
}
