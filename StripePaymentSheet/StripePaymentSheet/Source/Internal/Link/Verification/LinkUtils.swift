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
            }
        }
    }

    static func getLocalizedErrorMessage(from error: Error, apiClient: STPAPIClient) -> String {
        guard let errorCodeString = error._stp_error_code,
              let errorCode = ConsumerErrorCode(rawValue: errorCodeString) else {
            return apiClient.isTestmode ? error.localizedDescription : error.userFacingDescription(using: apiClient)
        }

        return errorCode.localizedDescription
    }

}
