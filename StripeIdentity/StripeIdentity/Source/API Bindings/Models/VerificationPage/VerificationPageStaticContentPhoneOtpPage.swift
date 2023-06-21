//
//  VerificationPageStaticContentPhoneOtpPage.swift
//  StripeIdentity
//
//  Created by Chen Cen on 6/14/23.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI {

    struct VerificationPageStaticContentPhoneOtpPage: Decodable, Equatable {
//        let title: String
//        let body: String
//        let redacted_phone_number: String?
//        let error_otp_message: String
//        let resend_button_text: String
//        let cannot_verify_button_text: String
//        let otp_length: Int

        var title: String = "Enter verification code"
        var body: String =  "Enter the code sent to you phone &phone_number& to continue."
        var redactedPhoneNumber: String? = "(***)*****35"
        var errorOtpMessage: String = "Error confirming verification code"
        var resendButtonText: String = "Resend code"
        var cannotVerifyButtonText: String = "I cannot verify this phone number"
        var otpLength: Int = 6
    }

}
