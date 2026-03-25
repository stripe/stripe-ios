//
//  CheckoutRequest.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/20/25.
//

import Foundation

/// The request format for `/quote` matches that of `/checkout`, so we use the same underlying model.
typealias QuoteRequest = CheckoutRequest

struct CheckoutRequest: Encodable {
    let cryptoOnrampSessionId: String

    enum CodingKeys: String, CodingKey {
        case cryptoOnrampSessionId = "cos_id"
    }
}
