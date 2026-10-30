//
//  STPPaymentMethodRevolutPayParams.swift
//  StripePayments
//

import Foundation

/// An object representing parameters used to create a RevolutPay Payment Method
public class STPPaymentMethodRevolutPayParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    public static func rootObjectName() -> String? {
        return "revolut_pay"
    }

    public static func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
