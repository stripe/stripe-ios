//
//  STPRadarOptions+Payments.swift
//  StripePayments
//
//  Created by Joyce Qin on 8/4/25.
//

import Foundation
@_spi(STP) import StripeCore

// MARK: - STPFormEncodable

extension STPRadarOptions: STPFormEncodable {

    @objc
    public class func rootObjectName() -> String? {
        return "radar_options"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: hCaptchaToken)): "hcaptcha_token",
        ]
    }
}
