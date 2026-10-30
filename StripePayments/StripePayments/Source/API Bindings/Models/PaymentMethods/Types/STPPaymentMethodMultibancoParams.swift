//
//  STPPaymentMethodMultibancoParams.swift
//  StripePayments
//
//  Created by Nick Porter on 4/22/24.
//

import Foundation

/// An object representing parameters used to create a Multibanco Payment Method
public class STPPaymentMethodMultibancoParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    public static func rootObjectName() -> String? {
        return "multibanco"
    }

    public static func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
