//
//  STPPaymentMethodVippsParams.swift
//  StripePayments
//

import Foundation

/// An object representing parameters used to create a Vipps Payment Method
public class STPPaymentMethodVippsParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    @objc
    public class func rootObjectName() -> String? {
        return "vipps"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
