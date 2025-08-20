//
//  CreatePaymentTokenResponse.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/9/25.
//

import Foundation

struct CreatePaymentTokenResponse: Codable {

    /// The created crypto wallet's unique identifier.
    let id: String
}
