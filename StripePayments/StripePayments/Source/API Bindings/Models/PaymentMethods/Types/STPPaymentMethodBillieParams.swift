//
//  STPPaymentMethodBillieParams.swift
//  StripePayments
//
//  Created by Eric Geniesse on 6/28/24.
//

import Foundation

/// An object representing parameters used to create a Billie Payment Method
public class STPPaymentMethodBillieParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    @objc
    public class func rootObjectName() -> String? {
        return "billie"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
