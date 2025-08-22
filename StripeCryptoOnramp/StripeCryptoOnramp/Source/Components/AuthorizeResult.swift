//
//  AuthorizeResult.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/22/25.
//

import Foundation

@_spi(CryptoOnrampSDKPreview)
public enum AuthorizeResult {

    /// Authorization was consented by the user.
    case consented

    /// Authorization was denied by the user.
    case denied

    /// The authorization flow was canceled by the user.
    case canceled
}
