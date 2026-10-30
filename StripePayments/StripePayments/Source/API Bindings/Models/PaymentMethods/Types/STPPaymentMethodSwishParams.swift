//
//  STPPaymentMethodSwishParams.swift
//  StripePayments
//
//  Created by Eduardo Urias on 9/21/23.
//

import Foundation

/// An object representing parameters used to create a Swish Payment Method
public class STPPaymentMethodSwishParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    public class func rootObjectName() -> String? {
        return "swish"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
