//
//  STPRadarOptions.swift
//  StripePayments
//
//  Created by Joyce Qin on 7/31/25.
//

import Foundation
@_spi(STP) import StripeCore

/// Values for STPRadarOptions
@_spi(STP) public class STPRadarOptions: NSObject {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    @objc public var hcaptchaToken: String?
    @objc public var iosVerificationObject: [String: String]?

    public init(hcaptchaToken: String? = nil, assertion: StripeAttest.Assertion? = nil) {
        self.hcaptchaToken = hcaptchaToken
        self.iosVerificationObject = assertion?.requestFields
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
            NSStringFromSelector(#selector(getter: iosVerificationObject)): "ios_verification_object",
        ]
    }
}
