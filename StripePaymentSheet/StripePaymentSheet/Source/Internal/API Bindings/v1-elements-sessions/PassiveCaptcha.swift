//
//  PassiveCaptcha.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 8/3/25.
//

import Foundation

/// PassiveCaptcha, delivered in the `v1/elements/sessions` response.
/// - Seealso: https://git.corp.stripe.com/stripe-internal/pay-server/blob/master/lib/elements/api/resources/elements_passive_captcha_resource.rb
struct PassiveCaptcha: Equatable, Hashable {

    let siteKey: String
    let rqData: String?

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

}
