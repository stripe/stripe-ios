//
//  STPPaymentMethodSwishParams.swift
//  StripePayments
//
//  Created by Eduardo Urias on 9/21/23.
//

import Foundation

/// An object representing parameters used to create a Swish Payment Method
public class STPPaymentMethodSwishParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    @objc
    public class func rootObjectName() -> String? {
        return "swish"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
