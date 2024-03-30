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
        let title: String
        let body: String
        let redactedPhoneNumber: String?
        let errorOtpMessage: String
        let resendButtonText: String
        let cannotVerifyButtonText: String
        let otpLength: Int
    }

}
