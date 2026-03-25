//
//  HTTPStatusError.swift
//  
//
//  Created by Mel Ludowise on 10/14/24.
//

import Foundation
@_spi(STP) import StripeCore

/// Error passed to the when the `ConnectComponentWebViewController.didFailLoadWithError`
/// when receiving an error status code loading the component web page
struct HTTPStatusError: Error, CustomNSError {
    /// The HTTP status code
    let errorCode: Int
}

extension HTTPStatusError: LocalizedError {
    var errorDescription: String? {
        NSError.stp_unexpectedErrorMessage()
    }
}

extension HTTPStatusError: CustomDebugStringConvertible {
    var debugDescription: String {
        "Component loaded with HTTP status \(errorCode)"
    }
}
