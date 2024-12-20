//
//  EmbeddedComponentError.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/22/24.
//

import Foundation

/// An error that can occur loading a Connect embedded component
/// - Important: Include  `@_spi(PrivateBetaConnect)` on import to gain access to this API.
@_spi(PrivateBetaConnect)
@_documentation(visibility: public)
public struct EmbeddedComponentError: Error, CustomDebugStringConvertible {
    @_documentation(visibility: public)
    public enum ErrorType: String {
        /// Failure to connect to Stripe's API
        case apiConnectionError = "api_connection_error"
        /// Failure to perform the authentication flow within Connect Embedded Components
        case authenticationError = "authentication_error"
        /// Account session create failed
        case accountSessionCreateError = "account_session_create_error"
        /// Request failed with an 4xx status code, typically caused by platform configuration issues
        case invalidRequestError = "invalid_request_error"
        /// Too many requests hit the API too quickly
        case rateLimitError = "rate_limit_error"
        /// API errors covering any other type of problem (e.g., a temporary problem with Stripe's servers),
        /// and are extremely uncommon
        case apiError = "api_error"
    }

    /// The type of error
    @_documentation(visibility: public)
    public let type: ErrorType

    /// A non localized description of the error.
    let description: String

    @_documentation(visibility: public)
    public var debugDescription: String {
        String("\(type.rawValue): \(description)")
    }
}
