//
//  AuthenticationResult.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/23/25.
//

/// The result of authentication after a user has been presented with an account verification step.
@_spi(CryptoOnrampSDKPreview)
public enum AuthenticationResult {

    /// Authentication was completed successfully. The customer ID is attached.
    case completed(customerId: String)

    /// Authentication was canceled by the user.
    case canceled
}
