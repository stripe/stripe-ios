//
//  Error+Extensions.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2026-08-12.
//

import Foundation
@_spi(STP) import StripeCore

extension Error {
    /// The `extra_fields` object of a Stripe API error response, if there is one.
    ///
    /// The API exposes some client-actionable details only through `extra_fields`, which is
    /// untyped, so it comes back as a raw dictionary.
    var extraFields: [String: Any]? {
        guard
            let error = self as? StripeError,
            case .apiError(let apiError) = error
        else {
            return nil
        }
        return apiError.allResponseFields["extra_fields"] as? [String: Any]
    }

    /// Whether this is a Stripe API error with a `4xx` status code.
    ///
    /// These are terminal: retrying the same request will fail the same way.
    var isClientError: Bool {
        guard
            let error = self as? StripeError,
            case .apiError(let apiError) = error,
            let statusCode = apiError.httpStatusCode
        else {
            return false
        }
        return (400...499).contains(statusCode)
    }
}
