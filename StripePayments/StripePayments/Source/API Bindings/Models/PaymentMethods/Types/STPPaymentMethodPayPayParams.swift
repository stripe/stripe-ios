//
//  STPPaymentMethodPayPayParams.swift
//  StripePayments
//
//  Created by Joyce Qin on 12/1/25.
//

import Foundation

/// An object representing parameters used to create a PayPal Payment Method :nodoc:
public class STPPaymentMethodPayPayParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    @objc
    public class func rootObjectName() -> String? {
        return "paypay"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
