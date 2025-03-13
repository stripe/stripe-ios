//
//  STPPaymentMethodVippsParams.swift
//  StripePayments
//
//  Created by Vincent Pandac on 3/24/25.
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
