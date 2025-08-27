//
//  AuthorizationResult.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/23/25.
//

import Foundation

@_spi(STP)
public enum AuthorizationResult {

    /// Authorization was consented by the user. The customer ID is attached.
    case consented(customerId: String)

    /// Authorization was denied by the user.
    case denied

    /// The authorization flow was canceled by the user.
    case canceled
}
