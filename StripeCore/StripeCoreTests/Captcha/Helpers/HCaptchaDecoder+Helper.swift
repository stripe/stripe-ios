//
//  HCaptchaDecoder+Helper.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 22/12/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import Foundation
@testable import StripePayments
import WebKit

class MockMessage: WKScriptMessage {
    override var body: Any {
        return storedBody
    }

    fileprivate let storedBody: Any

    init(message: Any) {
        storedBody = message
    }
}

// MARK: - Decoder Helpers
extension HCaptchaDecoder {
    func send(message: MockMessage) {
        userContentController(WKUserContentController(), didReceive: message)
    }
}

// MARK: - Result Helpers
extension HCaptchaDecoder.Result: Equatable {
    var error: HCaptchaError? {
        guard case .error(let error) = self else { return nil }
        return error
    }

    public static func == (lhs: HCaptchaDecoder.Result, rhs: HCaptchaDecoder.Result) -> Bool {
        switch (lhs, rhs) {
        case (.showHCaptcha, .showHCaptcha),
             (.didLoad, .didLoad):
            return true

        case (.token(let lht), .token(let rht)):
            return lht == rht

        case (.error(let lhe), .error(let rhe)):
            return lhe == rhe

        default:
            return false
        }
    }
}
