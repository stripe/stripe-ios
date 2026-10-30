//
//  STPPaymentMethodBillieParams.swift
//  StripePayments
//
//  Created by Eric Geniesse on 6/28/24.
//

import Foundation

/// An object representing parameters used to create a Billie Payment Method
public class STPPaymentMethodBillieParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    public class func rootObjectName() -> String? {
        return "billie"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
