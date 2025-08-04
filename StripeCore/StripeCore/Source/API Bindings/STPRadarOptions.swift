//
//  STPRadarOptions.swift
//  StripeCore
//
//  Created by Joyce Qin on 8/4/25.
//

import Foundation

/// Values for STPRadarOptions
@_spi(STP) public class STPRadarOptions: NSObject {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    @objc public var hCaptchaToken: String?

    public init(hCaptchaToken: String? = nil) {
        self.hCaptchaToken = hCaptchaToken
    }
}

// MARK: - Encodable
extension STPRadarOptions: Encodable {
    enum CodingKeys: String, CodingKey {
        case hCaptchaToken = "hcaptcha_token"
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(hCaptchaToken, forKey: .hCaptchaToken)
    }
}
