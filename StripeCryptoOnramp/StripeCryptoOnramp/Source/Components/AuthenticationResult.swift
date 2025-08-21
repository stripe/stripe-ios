//
//  AuthenticationResult.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/23/25.
//

/// The result after a user has been presented with Link authentication UI.
@_spi(CryptoOnrampSDKPreview)
public enum AuthenticationResult {

    /// Authentication was completed successfully. The customer ID is attached.
    case completed(customerId: String)

    /// Authentication was canceled by the user.
    case canceled
}
