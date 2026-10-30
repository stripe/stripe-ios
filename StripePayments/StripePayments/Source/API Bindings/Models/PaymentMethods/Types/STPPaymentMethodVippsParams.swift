//
//  STPPaymentMethodVippsParams.swift
//  StripePayments
//

import Foundation

/// An object representing parameters used to create a Vipps Payment Method
public class STPPaymentMethodVippsParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    public class func rootObjectName() -> String? {
        return "vipps"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [:]
    }
}
