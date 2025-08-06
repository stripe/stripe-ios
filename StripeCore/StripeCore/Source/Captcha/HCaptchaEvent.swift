//
//  HCaptchaEvent.swift
//  HCaptcha
//
//  Copyright © 2022 HCaptcha. All rights reserved.
//

import Foundation

/** Events which can be received from HCaptcha SDK
 */
@objc
enum HCaptchaEvent: Int, RawRepresentable {
    case open
    case expired
    case challengeExpired
    case close
    case error

    typealias RawValue = String

    var rawValue: RawValue {
        switch self {
        case .open:
            return "open"
        case .expired:
            return "expired"
        case .challengeExpired:
            return "challengeExpired"
        case .close:
            return "close"
        case .error:
            return "error"
        }
    }

    init?(rawValue: RawValue) {
        switch rawValue {
        case "open":
            self = .open
        case "expired":
            self = .expired
        case "challengeExpired":
            self = .challengeExpired
        case "close":
            self = .close
        case "error":
            self = .error
        default:
            return nil
        }
    }
}
