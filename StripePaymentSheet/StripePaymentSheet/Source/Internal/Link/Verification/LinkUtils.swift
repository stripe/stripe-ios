//
//  LinkUtils.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 6/24/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) import StripeCore

final class LinkUtils {

    /// Error codes for the consumer/Link API.
    enum ConsumerErrorCode: String {
        case consumerVerificationCodeInvalid = "consumer_verification_code_invalid"
        case consumerVerificationExpired = "consumer_verification_expired"
        case consumerVerificationMaxAttemptsExceeded = "consumer_verification_max_attempts_exceeded"
        case phoneNumberMismatch = "phone_number_mismatch"

        var localizedDescription: String {
            switch self {
            case .consumerVerificationCodeInvalid:
                return STPLocalizedString(
                    "The provided verification code is incorrect.",
                    "Error message shown when the user enters an incorrect verification code."
                )
            case .consumerVerificationExpired:
                return STPLocalizedString(
                    "The provided verification code has expired.",
                    "Error message shown when the user enters an expired verification code."
                )
            case .consumerVerificationMaxAttemptsExceeded:
                return STPLocalizedString(
                    "Too many attempts. Please try again in a few minutes.",
                    "Error message shown when the user enters an incorrect verification code too many times."
                )
            case .phoneNumberMismatch:
                return STPLocalizedString(
                    "That phone number is not associated with this account. Double check it and try again.",
                    "Error message shown when the user enters a phone number that doesn't match the account."
                )
            }
        }
    }

    static func getLocalizedErrorMessage(from error: Error) -> String {
        guard let errorCodeString = error._stp_error_code,
              let errorCode = ConsumerErrorCode(rawValue: errorCodeString) else {
            return error.localizedDescription
        }

        return errorCode.localizedDescription
    }

    static var codeSentSuccessMessage: String {
        return STPLocalizedString(
            "Code sent",
            "Text of a notification shown to the user when a login code is successfully sent."
        )
    }

}
