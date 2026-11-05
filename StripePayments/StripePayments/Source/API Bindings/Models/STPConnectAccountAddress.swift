//
//  STPConnectAccountAddress.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 8/2/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// An address to use with `STPConnectAccountParams`.
public class STPConnectAccountAddress: NSObject {

    /// City, district, suburb, town, or village.
    /// For addresses in Japan: City or ward.
    public var city: String?

    /// Two-letter country code (ISO 3166-1 alpha-2).
    /// - seealso: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
    public var country: String?

    /// Address line 1 (e.g., street, PO Box, or company name).
    /// For addresses in Japan: Block or building number.
    public var line1: String?

    /// Address line 2 (e.g., apartment, suite, unit, or building).
    /// For addresses in Japan: Building details.
    public var line2: String?

    /// ZIP or postal code.
    public var postalCode: String?

    /// State, county, province, or region.
    /// For addresses in Japan: Prefecture.
    public var state: String?

    /// Town or cho-me.
    /// This property only applies to Japanese addresses.
    public var town: String?

    /// :nodoc:
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// :nodoc:
    public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPConnectAccountAddress.self), self),
            // Properties
            "line1 = \(String(describing: line1))",
            "line2 = \(String(describing: line2))",
            "town = \(String(describing: town))",
            "city = \(String(describing: city))",
            "state = \(String(describing: state))",
            "postalCode = \(String(describing: postalCode))",
            "country = \(String(describing: country))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }
}

// MARK: - STPFormEncodable
extension STPConnectAccountAddress: STPFormEncodable {
    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPConnectAccountAddress.line1: "line1",
            \STPConnectAccountAddress.line2: "line2",
            \STPConnectAccountAddress.town: "town",
            \STPConnectAccountAddress.city: "city",
            \STPConnectAccountAddress.country: "country",
            \STPConnectAccountAddress.state: "state",
            \STPConnectAccountAddress.postalCode: "postal_code",
        ]
    }

    public class func rootObjectName() -> String? {
        return nil
    }
}
