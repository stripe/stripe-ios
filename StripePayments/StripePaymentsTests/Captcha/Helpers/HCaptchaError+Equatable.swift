//
//  HCaptchaError+Equatable.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 16/10/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import Foundation
@_spi(STP) @testable import StripePayments

extension HCaptchaError: Equatable {
    public static func == (lhs: HCaptchaError, rhs: HCaptchaError) -> Bool {
        switch (lhs, rhs) {
        case (.htmlLoadError, .htmlLoadError),
             (.apiKeyNotFound, .apiKeyNotFound),
             (.baseURLNotFound, .baseURLNotFound),
             (.wrongMessageFormat, .wrongMessageFormat),
             (.failedSetup, .failedSetup),
             (.sessionTimeout, .sessionTimeout),
             (.rateLimit, .rateLimit),
             (.invalidCustomTheme, .invalidCustomTheme),
             (.networkError, .networkError):
            return true
        case (.unexpected(let lhe as NSError), .unexpected(let rhe as NSError)):
            return lhe == rhe
        default:
            return false
        }
    }

    static func random() -> HCaptchaError {
        switch arc4random_uniform(7) {
        case 0: return .htmlLoadError
        case 1: return .apiKeyNotFound
        case 2: return .baseURLNotFound
        case 3: return .wrongMessageFormat
        case 4: return .failedSetup
        case 5: return .sessionTimeout
        case 6: return .rateLimit
        case 7: return .invalidCustomTheme
        case 8: return .networkError
        default: return .unexpected(NSError())
        }
    }
}
