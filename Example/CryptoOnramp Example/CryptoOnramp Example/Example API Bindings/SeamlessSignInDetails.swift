//
//  SeamlessSignInDetails.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 10/22/25.
//

import Foundation

/// Information related to successful authentication that can be restored
/// on subsequent launches for easier sign-in.
struct SeamlessSignInDetails: Codable {

    /// The user's email address.
    let email: String

    /// The authentication token with Link auth intent from a prior session.
    let token: String
}
