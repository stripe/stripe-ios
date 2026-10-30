//
//  STPPaymentMethodSunbitParams.swift
//  StripePayments
//
//  Created by Eric Geniesse on 6/27/24.
//

import Foundation

/// An object representing parameters used to create a Sunbit Payment Method
public class STPPaymentMethodSunbitParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    public class func rootObjectName() -> String? {
        return "sunbit"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
