//
//  STPRadarOptions.swift
//  StripePayments
//
//  Created by Joyce Qin on 7/31/25.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

/// Values for STPRadarOptions
@_spi(InternalOnlyAPI) public class STPRadarOptions: NSObject {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    public var hcaptchaToken: String?
    public var iosVerificationObject: [String: String]?

    public init(hcaptchaToken: String? = nil, assertion: StripeAttest.Assertion? = nil) {
        self.hcaptchaToken = hcaptchaToken
        self.iosVerificationObject = assertion?.requestFields
    }
}

// MARK: - STPFormEncodable

extension STPRadarOptions: STPFormEncodable {

    public class func rootObjectName() -> String? {
        return "radar_options"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPRadarOptions.hcaptchaToken: "hcaptcha_token",
            \STPRadarOptions.iosVerificationObject: "ios_verification_object",
        ]
    }
}
