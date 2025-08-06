//
//  STPHCaptchaChallenge.swift
//  StripePayments
//
//  Created by Joyce Qin on 8/5/25.
//

import Foundation

@_spi(STP) public func fetchPassiveHCaptchaToken(passiveCaptcha: PassiveCaptcha?) async -> String? {
    return await withCheckedContinuation { continuation in
        guard let passiveCaptcha,
              let hcaptcha = try? HCaptcha(apiKey: passiveCaptcha.siteKey, passiveApiKey: true, baseURL: URL(string: "http://localhost"), rqdata: passiveCaptcha.rqData) else {
            continuation.resume(returning: nil)
            return
        }
        hcaptcha.didFinishLoading {
            hcaptcha.validate { result in
                let token = try? result.dematerialize()
                continuation.resume(returning: token)
            }
        }
    }
}
