//
//  IdentityVerificationResult.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/5/25.
//

import Foundation

/// Encapsulates the possible return values for `CryptoOnrampCoordinator.promptForIdentityVerification()`.
@_spi(STP)
public enum IdentityVerificationResult {

    /// The user has completed uploading their documents.
    case completed

    /// The user did not complete uploading their document, and should be allowed to try again.
    case canceled
}
