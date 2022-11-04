//
//  STPPhoneNumberValidator.swift
//  StripePaymentsUI
//
//  Created by Jack Flintermann on 10/16/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

@_spi(STP) public class STPPhoneNumberValidator: NSObject {

    class func stringIsValidPhoneNumber(_ string: String) -> Bool {
        if string == "" {
            return false
        }
        return self.stringIsValidPhoneNumber(string, forCountryCode: nil)
    }

    @_spi(STP) public class func stringIsValidPhoneNumber(
        _ string: String,
        forCountryCode nillableCode: String?
    ) -> Bool {
        let countryCode = self.countryCodeOrCurrentLocaleCountry(from: nillableCode)
        if let phoneNumber = PhoneNumber(number: string, countryCode: countryCode) {
            return phoneNumber.isComplete
        } else {
            return !string.isEmpty
        }
    }

    @objc(formattedSanitizedPhoneNumberForString:) class func formattedSanitizedPhoneNumber(
        for string: String
    ) -> String {
        return self.formattedSanitizedPhoneNumber(
            for: string,
            forCountryCode: nil
        )
    }

    @objc(formattedSanitizedPhoneNumberForString:forCountryCode:)
    class func formattedSanitizedPhoneNumber(
        for string: String,
        forCountryCode nillableCode: String?
    ) -> String {
        let countryCode = self.countryCodeOrCurrentLocaleCountry(from: nillableCode)
        let sanitized = STPCardValidator.sanitizedNumericString(for: string)
        return self.formattedPhoneNumber(
            for: sanitized,
            forCountryCode: countryCode
        )
    }

    @objc(formattedRedactedPhoneNumberForString:) class func formattedRedactedPhoneNumber(
        for string: String
    ) -> String {
        return self.formattedRedactedPhoneNumber(
            for: string,
            forCountryCode: nil
        )
    }

    @objc(formattedRedactedPhoneNumberForString:forCountryCode:)
    class func formattedRedactedPhoneNumber(
        for string: String,
        forCountryCode nillableCode: String?
    ) -> String {
        let countryCode = self.countryCodeOrCurrentLocaleCountry(from: nillableCode)
        let scanner = Scanner(string: string)
        var prefix: NSString? = NSString()
        if #available(iOS 13.0, *) {
            prefix = scanner.scanUpToString("*") as NSString?
        } else {
            #if !TARGET_OS_MACCATALYST
                scanner.scanUpTo("*", into: &prefix)
            #endif
        }
        var number = (string as NSString).replacingOccurrences(
            of: (prefix ?? "") as String,
            with: ""
        )
        number = number.replacingOccurrences(of: "*", with: "•")
        number = self.formattedPhoneNumber(
            for: number,
            forCountryCode: countryCode
        )
        return "\(prefix ?? "") \(number)"
    }

    class func countryCodeOrCurrentLocaleCountry(from nillableCode: String?) -> String {
        var countryCode = nillableCode
        if countryCode == nil {
            countryCode = NSLocale.autoupdatingCurrent.regionCode
        }
        return countryCode ?? ""
    }

    class func formattedPhoneNumber(
        for string: String,
        forCountryCode countryCode: String
    ) -> String {

        if !(countryCode == "US") {
            return string
        }
        if string.count >= 6 {
            return
                "(\(string.stp_safeSubstring(to: 3))) \(string.stp_safeSubstring(to: 6).stp_safeSubstring(from: 3))-\(string.stp_safeSubstring(to: 10).stp_safeSubstring(from: 6))"
        } else if string.count >= 3 {
            return "(\(string.stp_safeSubstring(to: 3))) \(string.stp_safeSubstring(from: 3))"
        }
        return string
    }
}
