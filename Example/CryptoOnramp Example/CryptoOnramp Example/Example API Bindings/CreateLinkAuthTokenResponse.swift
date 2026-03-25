//
//  CreateLinkAuthTokenResponse.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 10/15/25.
//

import Foundation

struct CreateLinkAuthTokenResponse: Decodable {
    let linkAuthTokenClientSecret: String
    let expiresIn: Int
}
