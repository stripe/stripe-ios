//
//  CardScanSheetError.swift
//  StripeCardScan
//
//  Created by Jaime Park on 11/17/21.
//

import Foundation
@_spi(STP) import StripeCore

/**
 Errors specific to the `CardImageVerificationSheet`.
 */
public enum CardScanSheetError: Error {
    /// The provided client secret is invalid.
    case invalidClientSecret
    /// An unknown error.
    case unknown(debugDescription: String)
}

extension CardScanSheetError: LocalizedError {
    /// Localized description of the error
    public var localizedDescription: String {
        return NSError.stp_unexpectedErrorMessage()
    }
}

extension CardScanSheetError: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .invalidClientSecret:
            return "Invalid client secret"
        case .unknown(debugDescription: let debugDescription):
            return debugDescription
        }
    }
}
