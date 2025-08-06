//
//  STPRadarOptions.swift
//  StripePayments
//
//  Created by Joyce Qin on 7/31/25.
//

import Foundation

/// Values for STPRadarOptions
class STPRadarOptions: NSObject {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    @objc public var hcaptchaToken: String?

    public init(hcaptchaToken: String? = nil) {
        self.hcaptchaToken = hcaptchaToken
    }
}

// MARK: - STPFormEncodable

extension STPRadarOptions: STPFormEncodable {

    @objc
    public class func rootObjectName() -> String? {
        return "radar_options"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: hcaptchaToken)): "hcaptcha_token",
        ]
    }
}
