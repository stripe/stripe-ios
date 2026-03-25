//
//  CreateAuthIntentResponse.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 10/15/25.
//

import Foundation

struct CreateAuthIntentResponse: Decodable {
    enum State: String, Decodable {
        case created, authenticated, consented, rejected, expired
    }

    let authIntentId: String
    let existing: Bool
    let state: State
    let token: String
}
