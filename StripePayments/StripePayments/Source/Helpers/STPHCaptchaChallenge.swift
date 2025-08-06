//
//  STPHCaptchaChallenge.swift
//  StripePayments
//
//  Created by Joyce Qin on 8/5/25.
//

import Foundation

@_spi(STP) public func startPassiveHCaptchaChallengeIfNecessary(siteKey: String?, rqdata: String?, completion: @escaping (String?) -> Void) {
    guard let siteKey,
          let hcaptcha = try? HCaptcha(apiKey: siteKey, passiveApiKey: true, baseURL: URL(string: "http://localhost"), rqdata: rqdata) else {
        completion(nil)
        return
    }
    hcaptcha.didFinishLoading {
        hcaptcha.validate { result in
            let token = try? result.dematerialize()
            completion(token)
        }
    }
}
