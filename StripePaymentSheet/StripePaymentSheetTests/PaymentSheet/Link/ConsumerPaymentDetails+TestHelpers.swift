//
//  ConsumerPaymentDetails+TestHelpers.swift
//  StripePaymentSheetTests
//
//  Test-only factory methods for types that use `init(from:)` in production.
//

import Foundation
@_spi(STP) @testable import StripePaymentSheet

extension ConsumerSession {
    static func makeForTest(
        clientSecret: String,
        emailAddress: String,
        redactedFormattedPhoneNumber: String,
        unredactedPhoneNumber: String? = nil,
        phoneNumberCountry: String? = nil,
        verificationSessions: [[String: Any]] = [],
        supportedPaymentDetailsTypes: Set<ConsumerPaymentDetails.DetailsType> = [.card, .bankAccount],
        mobileFallbackWebviewParams: MobileFallbackWebviewParams? = nil,
        currentAuthenticationLevel: String? = nil,
        minimumAuthenticationLevel: String? = nil
    ) -> ConsumerSession {
        var json: [String: Any] = [
            "clientSecret": clientSecret,
            "emailAddress": emailAddress,
            "redactedFormattedPhoneNumber": redactedFormattedPhoneNumber,
            "supportPaymentDetailsTypes": supportedPaymentDetailsTypes.map(\.rawValue),
            "verificationSessions": verificationSessions,
        ]
        if let unredactedPhoneNumber {
            json["unredactedPhoneNumber"] = unredactedPhoneNumber
        }
        if let phoneNumberCountry {
            json["phoneNumberCountry"] = phoneNumberCountry
        }
        if let currentAuthenticationLevel {
            json["currentAuthenticationLevel"] = currentAuthenticationLevel
        }
        if let minimumAuthenticationLevel {
            json["minimumAuthenticationLevel"] = minimumAuthenticationLevel
        }
        let data = try! JSONSerialization.data(withJSONObject: json)
        return try! JSONDecoder().decode(ConsumerSession.self, from: data)
    }
}
