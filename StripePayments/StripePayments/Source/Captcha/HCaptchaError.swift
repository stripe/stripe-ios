//
//  HCaptchaError.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 22/03/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import Foundation

/// The codes of possible errors thrown by HCaptcha
enum HCaptchaError: Error, CustomStringConvertible {

    /// Unexpected error
    case unexpected(Error)

    /// Internet connection is missing
    case networkError

    /// Could not load the HTML embedded in the bundle
    case htmlLoadError

    /// HCaptchaKey was not provided
    case apiKeyNotFound

    /// HCaptchaDomain was not provided
    case baseURLNotFound

    /// Received an unexpected message from javascript
    case wrongMessageFormat

    /// HCaptcha setup failed
    case failedSetup

    /// HCaptcha response or session expired
    case sessionTimeout

    /// user closed HCaptcha without answering
    case challengeClosed

    /// HCaptcha server rate-limited user request
    case rateLimit

    /// Invalid custom theme passed
    case invalidCustomTheme

    static func == (lhs: HCaptchaError, rhs: HCaptchaError) -> Bool {
        return lhs.description == rhs.description
    }

    /// A human-readable description for each error
    var description: String {
        switch self {
        case .unexpected(let error):
            return "Unexpected Error: \(error)"

        case .networkError:
            return "Network issues"

        case .htmlLoadError:
            return "Could not load embedded HTML"

        case .apiKeyNotFound:
            return "HCaptchaKey not provided"

        case .baseURLNotFound:
            return "HCaptchaDomain not provided"

        case .wrongMessageFormat:
            return "Unexpected message from javascript"

        case .failedSetup:
            return """
            ⚠️ WARNING! HCaptcha wasn't successfully configured. Please double check your HCaptchaKey and HCaptchaDomain.
            Also check that you're using the hCaptcha **SITE KEY** for client side integration.
            """

        case .sessionTimeout:
            return "Response expired and need to re-verify"

        case .challengeClosed:
            return "User closed challenge without answering"

        case .rateLimit:
            return "User was rate-limited"

        case .invalidCustomTheme:
            return "Invalid JSON or JSObject as customTheme"
        }
    }
}
