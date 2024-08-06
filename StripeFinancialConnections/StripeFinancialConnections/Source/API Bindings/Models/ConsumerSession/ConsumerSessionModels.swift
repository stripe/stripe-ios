//
//  LookupConsumerSessionResponse.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/25/23.
//

import Foundation
@_spi(STP) import StripeCore

struct ConsumerSessionData: Decodable {
    let clientSecret: String
    let emailAddress: String
    let redactedFormattedPhoneNumber: String
    let verificationSessions: [VerificationSession]

    var isVerified: Bool {
        verificationSessions.contains(where: { $0.state == .verified })
    }
}

struct VerificationSession: Decodable {
    enum SessionType: String, SafeEnumDecodable, Equatable {
        case signUp = "signup"
        case email = "email"
        case sms = "sms"
        case unparsable
    }

    enum SessionState: String, SafeEnumDecodable, Equatable {
        case started
        case failed
        case verified
        case canceled
        case expired
        case unparsable
    }

    let type: SessionType
    let state: SessionState
}

struct LookupConsumerSessionResponse: Decodable {
    let exists: Bool
    let accountId: String?
    let publishableKey: String?
    let consumerSession: ConsumerSessionData?
}

struct LinkSignUpResponse: Decodable {
    let accountId: String
    let publishableKey: String
    let consumerSession: ConsumerSessionData
}

struct AttachLinkConsumerToLinkAccountSessionResponse: Decodable {
    let id: String
    let clientSecret: String
}

struct ConsumerSessionResponse: Decodable {
    let consumerSession: ConsumerSessionData
}
