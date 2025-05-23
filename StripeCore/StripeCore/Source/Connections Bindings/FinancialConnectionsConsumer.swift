//
//  FinancialConnectionsConsumer.swift
//  StripeCore
//
//  Created by Mat Schmid on 5/20/25.
//

import Foundation

@_spi(STP) public struct FinancialConnectionsConsumer {
    @_spi(STP) public let publishableKey: String?
    @_spi(STP) public let clientSecret: String
    @_spi(STP) public let emailAddress: String
    @_spi(STP) public let redactedFormattedPhoneNumber: String
    @_spi(STP) public let verificationSessions: [VerificationSession]

    @_spi(STP) public init(
        publishableKey: String?,
        clientSecret: String,
        emailAddress: String,
        redactedFormattedPhoneNumber: String,
        verificationSessions: [VerificationSession]
    ) {
        self.publishableKey = publishableKey
        self.clientSecret = clientSecret
        self.emailAddress = emailAddress
        self.redactedFormattedPhoneNumber = redactedFormattedPhoneNumber
        self.verificationSessions = verificationSessions
    }
}

@_spi(STP) public struct VerificationSession: Decodable {
    @_spi(STP) public enum SessionType: String, SafeEnumDecodable, Equatable {
        case signUp = "SIGNUP"
        case email = "EMAIL"
        case sms = "SMS"
        case unparsable
    }

    @_spi(STP) public enum SessionState: String, SafeEnumDecodable, Equatable {
        case started = "STARTED"
        case failed = "FAILED"
        case verified = "VERIFIED"
        case canceled = "CANCELED"
        case expired = "EXPIRED"
        case unparsable
    }

    @_spi(STP) public let type: SessionType
    @_spi(STP) public let state: SessionState

    @_spi(STP) public init(type: SessionType, state: SessionState) {
        self.type = type
        self.state = state
    }
}
