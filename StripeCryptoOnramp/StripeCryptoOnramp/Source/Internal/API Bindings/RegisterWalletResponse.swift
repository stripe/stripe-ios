//
//  RegisterWalletResponse.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/6/25.
//

import Foundation

struct RegisterWalletResponse: Codable {

    /// The created crypto wallet's unique identifier.
    let id: String
}
