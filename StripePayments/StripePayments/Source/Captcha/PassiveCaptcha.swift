//
//  PassiveCaptcha.swift
//  StripePayments
//
//  Created by Joyce Qin on 8/3/25.
//

import Foundation
@_spi(STP) import StripeCore

/// PassiveCaptcha, delivered in the `v1/elements/sessions` response.
/// - Seealso: https://git.corp.stripe.com/stripe-internal/pay-server/blob/master/lib/elements/api/resources/elements_passive_captcha_resource.rb
@_spi(STP) public struct PassiveCaptcha: Equatable, Hashable {

    let siteKey: String
    let rqdata: String?

    /// Helper method to decode the `v1/elements/sessions` response's `passive_captcha` hash.
    /// - Parameter response: The value of the `passive_captcha` key in the `v1/elements/sessions` response.
    public static func decoded(
        fromAPIResponse response: [AnyHashable: Any]?
    ) -> PassiveCaptcha? {
        guard let response else {
            return nil
        }

        guard let siteKey = response["site_key"] as? String
        else {
            return nil
        }

        // Optional
        let rqdata = response["rqdata"] as? String
        return PassiveCaptcha(
            siteKey: siteKey,
            rqdata: rqdata
        )
    }

    @_spi(STP) public static func fetchPassiveHCaptchaToken(passiveCaptcha: PassiveCaptcha?, completion: @escaping (String?) -> Void) {
        guard let passiveCaptcha,
              let hcaptcha = try? HCaptcha(apiKey: passiveCaptcha.siteKey, passiveApiKey: true, baseURL: URL(string: "http://localhost"), rqdata: passiveCaptcha.rqdata) else {
            completion(nil)
            return
        }

        var hasCompleted = false
        let timeoutDuration: TimeInterval = 10.0

        // Set up timeout timer
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutDuration) {
            if !hasCompleted {
                // Send analytics for timeout
                STPAnalyticsClient.sharedClient.logPassiveCaptchaTimeout(siteKey: passiveCaptcha.siteKey)
                completion(nil)
            }
        }

        hcaptcha.didFinishLoading {
            hcaptcha.validate { result in
                hasCompleted = true
                let token = try? result.dematerialize()
                completion(token)
            }
        }
    }

}

extension STPAnalyticsClient {
    func logPassiveCaptchaTimeout(siteKey: String) {
        log(
            analytic: GenericAnalytic(event: .passiveCaptchaTimeout, params: ["site_key": siteKey])
        )
    }
}
