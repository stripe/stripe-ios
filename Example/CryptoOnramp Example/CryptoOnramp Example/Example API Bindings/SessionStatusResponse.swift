//
//  SessionStatusResponse.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/20/25.
//

import Foundation

struct SessionStatusResponse: Decodable {
    let sessionId: String
    let status: String
    let updatedAt: Date
}
