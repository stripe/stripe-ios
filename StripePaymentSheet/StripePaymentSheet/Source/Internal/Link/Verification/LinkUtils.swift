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
        case consumerVerificationNotFound = "consumer_verification_not_found"
        case consumerVerificationMaxAttemptsExceeded = "consumer_verification_max_attempts_exceeded"
        case phoneNumberMissing = "phone_number_missing"
        case phoneNumberMismatch = "phone_number_mismatch"

        var localizedDescription: String {
            switch self {
            case .phoneNumberMissing:
                return STPLocalizedString("Enter the phone number on your Link account.", "Error when Link email verification requires a phone number.")
            case .phoneNumberMismatch:
                return STPLocalizedString("This phone number doesn't match your Link account. Please try again.", "Error when the phone number entered before Link email verification does not match the account.")
            case .consumerVerificationCodeInvalid:
                return STPLocalizedString(
                    "The provided verification code is incorrect.",
                    "Error message shown when the user enters an incorrect verification code."
                )
            case .consumerVerificationExpired, .consumerVerificationNotFound:
                return STPLocalizedString(
                    "The provided verification code has expired.",
                    "Error message shown when the user enters an expired verification code."
                )
            case .consumerVerificationMaxAttemptsExceeded:
                return STPLocalizedString(
                    "Too many attempts. Please try again in a few minutes.",
                    "Error message shown when the user enters an incorrect verification code too many times."
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

}
