//
//  FinancialConnectionsConsumer.swift
//  StripeCore
//
//  Created by Mat Schmid on 5/20/25.
//

import Foundation

@_spi(InternalOnlyAPI) public struct FinancialConnectionsConsumer {
    @_spi(InternalOnlyAPI) public let publishableKey: String?
    @_spi(InternalOnlyAPI) public let clientSecret: String
    @_spi(InternalOnlyAPI) public let emailAddress: String
    @_spi(InternalOnlyAPI) public let redactedFormattedPhoneNumber: String
    @_spi(InternalOnlyAPI) public let verificationSessions: [VerificationSession]
    @_spi(InternalOnlyAPI) public let linkBrand: LinkBrand?

    @_spi(InternalOnlyAPI) public init(
        publishableKey: String?,
        clientSecret: String,
        emailAddress: String,
        redactedFormattedPhoneNumber: String,
        verificationSessions: [VerificationSession],
        linkBrand: LinkBrand? = nil
    ) {
        self.publishableKey = publishableKey
        self.clientSecret = clientSecret
        self.emailAddress = emailAddress
        self.redactedFormattedPhoneNumber = redactedFormattedPhoneNumber
        self.verificationSessions = verificationSessions
        self.linkBrand = linkBrand
    }
}

@_spi(InternalOnlyAPI) public struct VerificationSession: Decodable {
    @_spi(InternalOnlyAPI) public enum SessionType: String, SafeEnumDecodable, Equatable {
        case signUp = "SIGNUP"
        case email = "EMAIL"
        case sms = "SMS"
        case unparsable
    }

    @_spi(InternalOnlyAPI) public enum SessionState: String, SafeEnumDecodable, Equatable {
        case started = "STARTED"
        case failed = "FAILED"
        case verified = "VERIFIED"
        case canceled = "CANCELED"
        case expired = "EXPIRED"
        case unparsable
    }

    @_spi(InternalOnlyAPI) public let type: SessionType
    @_spi(InternalOnlyAPI) public let state: SessionState

    @_spi(InternalOnlyAPI) public init(type: SessionType, state: SessionState) {
        self.type = type
        self.state = state
    }
}
