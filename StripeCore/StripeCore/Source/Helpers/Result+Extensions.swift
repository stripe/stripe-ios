//
//  Result+Extensions.swift
//  StripeCore
//
//  Created by Mat Schmid on 2024-07-09.
//

import Foundation

@_spi(STP) public extension Result {
    /// Whether or not the result is a success.
    var success: Bool {
        switch self {
        case .success: true
        case .failure: false
        }
    }

    /// Returns the error if the result is a failure.
    var error: Error? {
        guard case .failure(let error) = self else { return nil }
        return error
    }
}
