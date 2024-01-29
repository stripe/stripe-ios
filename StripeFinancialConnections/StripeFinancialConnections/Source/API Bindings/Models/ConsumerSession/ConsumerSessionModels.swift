//
//  LookupConsumerSessionResponse.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/25/23.
//

import Foundation

struct ConsumerSessionData: Decodable {
    let clientSecret: String
    let emailAddress: String
    let redactedFormattedPhoneNumber: String
}

struct LookupConsumerSessionResponse: Decodable {
    let consumerSession: ConsumerSessionData?
    let exists: Bool
    let accountId: String?
}

struct ConsumerSessionResponse: Decodable {
    let consumerSession: ConsumerSessionData
    let authSessionClientSecret: String?
}
