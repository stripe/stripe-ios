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

    /// A consumer session is considered verified if the `state == .verified` or the `type == .signUp`.
    var isVerified: Bool {
        verificationSessions.contains(where: { $0.state == .verified })
        || verificationSessions.contains(where: { $0.type == .signUp })
    }
}

struct VerificationSession: Decodable {
    enum SessionType: String, SafeEnumDecodable, Equatable {
        case signUp = "SIGNUP"
        case email = "EMAIL"
        case sms = "SMS"
        case unparsable
    }

    enum SessionState: String, SafeEnumDecodable, Equatable {
        case started = "STARTED"
        case failed = "FAILED"
        case verified = "VERIFIED"
        case canceled = "CANCELED"
        case expired = "EXPIRED"
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
