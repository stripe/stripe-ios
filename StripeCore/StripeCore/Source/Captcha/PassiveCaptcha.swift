//
//  PassiveCaptcha.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 8/3/25.
//

import Foundation

/// PassiveCaptcha, delivered in the `v1/elements/sessions` response.
/// - Seealso: https://git.corp.stripe.com/stripe-internal/pay-server/blob/master/lib/elements/api/resources/elements_passive_captcha_resource.rb
@_spi(STP) public struct PassiveCaptcha: Equatable, Hashable {

    public let siteKey: String
    public let rqData: String?

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
        let rqData = response["rqdata"] as? String
        return PassiveCaptcha(
            siteKey: siteKey,
            rqData: rqData
        )
    }

    @available(iOSApplicationExtension, unavailable)
    @_spi(STP) public func fetchPassiveHCaptchaToken() async -> String? {
        return await withCheckedContinuation { continuation in
            guard let hcaptcha = try? HCaptcha(apiKey: siteKey, passiveApiKey: true, baseURL: URL(string: "http://localhost"), rqdata: rqData) else {
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

}
