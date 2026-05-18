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
    let linkBrand: LinkBrand?
}

struct AttachLinkConsumerToLinkAccountSessionResponse: Decodable {
    let id: String
    let clientSecret: String
}

struct ConsumerSessionResponse: Decodable {
    let consumerSession: ConsumerSessionData
    let linkBrand: LinkBrand?
}

extension LinkSignUpResponse {
    private enum CodingKeys: String, CodingKey {
        case accountId
        case publishableKey
        case consumerSession
        case linkBrand
        case brand
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accountId = try container.decode(String.self, forKey: .accountId)
        self.publishableKey = try container.decode(String.self, forKey: .publishableKey)
        self.consumerSession = try container.decode(ConsumerSessionData.self, forKey: .consumerSession)
        self.linkBrand = try container.decodeIfPresent(LinkBrand.self, forKey: .linkBrand)
            ?? container.decodeIfPresent(LinkBrand.self, forKey: .brand)
    }
}

extension ConsumerSessionResponse {
    private enum CodingKeys: String, CodingKey {
        case consumerSession
        case linkBrand
        case brand
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.consumerSession = try container.decode(ConsumerSessionData.self, forKey: .consumerSession)
        self.linkBrand = try container.decodeIfPresent(LinkBrand.self, forKey: .linkBrand)
            ?? container.decodeIfPresent(LinkBrand.self, forKey: .brand)
    }
}
