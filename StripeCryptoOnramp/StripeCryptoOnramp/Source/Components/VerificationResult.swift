//
//  VerificationResult.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/23/25.
//

/// The result after a user has been presented with an OTP verification step.
@_spi(CryptoOnrampSDKPreview)
public enum VerificationResult {

    /// Verification was completed successfully. The customer ID is attached.
    case completed(customerId: String)

    /// Verification was canceled by the user.
    case canceled
}
