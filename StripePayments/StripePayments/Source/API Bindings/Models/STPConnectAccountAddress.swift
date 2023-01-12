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
    @objc public var city: String?

    /// Two-letter country code (ISO 3166-1 alpha-2).
    /// - seealso: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
    @objc public var country: String?

    /// Address line 1 (e.g., street, PO Box, or company name).
    /// For addresses in Japan: Block or building number.
    @objc public var line1: String?

    /// Address line 2 (e.g., apartment, suite, unit, or building).
    /// For addresses in Japan: Building details.
    @objc public var line2: String?

    /// ZIP or postal code.
    @objc public var postalCode: String?

    /// State, county, province, or region.
    /// For addresses in Japan: Prefecture.
    @objc public var state: String?

    /// Town or cho-me.
    /// This property only applies to Japanese addresses.
    @objc public var town: String?

    /// :nodoc:
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
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
    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: line1)): "line1",
            NSStringFromSelector(#selector(getter: line2)): "line2",
            NSStringFromSelector(#selector(getter: town)): "town",
            NSStringFromSelector(#selector(getter: city)): "city",
            NSStringFromSelector(#selector(getter: country)): "country",
            NSStringFromSelector(#selector(getter: state)): "state",
            NSStringFromSelector(#selector(getter: postalCode)): "postal_code",
        ]
    }

    @objc
    public class func rootObjectName() -> String? {
        return nil
    }
}
