//
//  STPPaymentMethodAmazonPayParams.swift
//  StripePayments
//
//  Created by Nick Porter on 2/21/24.
//

import Foundation

/// An object representing parameters used to create a AmazonPay Payment Method
public class STPPaymentMethodAmazonPayParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    public class func rootObjectName() -> String? {
        return "amazon_pay"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [:]
    }
}
