//
//  LookupConsumerSessionResponse.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/25/23.
//

import Foundation

struct ConsumerSession: Decodable {
    let clientSecret: String
    let emailAddress: String
    let redactedPhoneNumber: String
}

struct LookupConsumerSessionResponse: Decodable {
    let consumerSession: ConsumerSession?
    let exists: Bool
    let accountId: String?
}
