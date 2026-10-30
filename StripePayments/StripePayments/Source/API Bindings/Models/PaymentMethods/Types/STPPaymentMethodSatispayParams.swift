//
//  STPPaymentMethodSatispayParams.swift
//  StripePayments
//
//  Created by Eric Geniesse on 7/1/24.
//

import Foundation

/// An object representing parameters used to create a Sunbit Payment Method
public class STPPaymentMethodSatispayParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    public class func rootObjectName() -> String? {
        return "satispay"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [:]
    }
}
