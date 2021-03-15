//
//  IdentityVerificationSheetError.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 3/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/**
 Errors specific to the `IdentityVerificationSheet`.
 */
public enum IdentityVerificationSheetError: Error {
    /// The provided client secret is invalid.
    case invalidClientSecret
    /// An unknown error.
    case unknown(debugDescription: String)

    /// Localized description of the error
    public var localizedDescription: String {
        return NSError.stp_unexpectedErrorMessage()
    }
}
