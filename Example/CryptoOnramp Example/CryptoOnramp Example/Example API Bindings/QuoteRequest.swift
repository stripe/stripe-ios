//
//  QuoteRequest.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/20/25.
//

import Foundation

struct QuoteRequest: Encodable {
    let cryptoOnrampSessionId: String

    enum CodingKeys: String, CodingKey {
        case cryptoOnrampSessionId = "cos_id"
    }
}

