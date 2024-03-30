//
//  STPPaymentMethodRevolutPayParams.swift
//  StripePayments
//

import Foundation

/// An object representing parameters used to create a RevolutPay Payment Method
public class STPPaymentMethodRevolutPayParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    @objc
    public static func rootObjectName() -> String? {
        return "revolut_pay"
    }

    @objc
    public static func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
