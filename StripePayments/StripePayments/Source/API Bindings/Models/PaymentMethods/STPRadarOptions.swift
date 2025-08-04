//
//  STPRadarOptions.swift
//  StripePayments
//
//  Created by Joyce Qin on 7/31/25.
//

import Foundation

/// Values for STPRadarOptions
@_spi(STP) public class STPRadarOptions: NSObject {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// The HCaptcha token from the passive HCaptcha
    @objc public var hCaptchaToken: String?

    public init(hCaptchaToken: String? = nil) {
        self.hCaptchaToken = hCaptchaToken
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
            NSStringFromSelector(#selector(getter: hCaptchaToken)): "hcaptcha_token",
        ]
    }
}
