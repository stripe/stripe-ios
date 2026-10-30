//
//  STPPaymentMethodPayPayParams.swift
//  StripePayments
//
//  Created by Joyce Qin on 12/1/25.
//

import Foundation

/// An object representing parameters used to create a PayPay Payment Method :nodoc:
public class STPPaymentMethodPayPayParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    public class func rootObjectName() -> String? {
        return "paypay"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [:]
    }
}
