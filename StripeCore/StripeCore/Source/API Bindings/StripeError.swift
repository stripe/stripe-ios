//
//  StripeError.swift
//  StripeCore
//
//  Created by David Estes on 8/11/21.
//

import Foundation

/// Error codes returned from STPAPIClient
enum StripeError: Error {
    /// The server returned an API error
    case apiError(StripeAPIError)
}
