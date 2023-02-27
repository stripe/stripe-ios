//
//  VerificationSession.swift
//  StripePaymentSheet
//
//  Created by Cameron Sabol on 2/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripePayments
import UIKit

extension ConsumerSession {
    struct VerificationSession: Codable {
        enum SessionType: String, SafeEnumCodable {
            case signup = "SIGNUP"
            case email = "EMAIL"
            case sms = "SMS"
            case unparsable = ""
        }

        enum SessionState: String, SafeEnumCodable {
            case started = "STARTED"
            case failed = "FAILED"
            case verified = "VERIFIED"
            case canceled = "CANCELED"
            case expired = "EXPIRED"
            case unparsable = ""
        }

        let type: SessionType
        let state: SessionState
    }
}

extension Sequence where Iterator.Element == ConsumerSession.VerificationSession {
    var containsVerifiedSMSSession: Bool {
        return contains(where: { $0.type == .sms && $0.state == .verified })
    }

    var isVerifiedForSignup: Bool {
        return contains(where: { $0.type == .signup && $0.state == .started })
    }
}
