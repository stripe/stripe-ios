//
//  STPPaymentMethodAmazonPayParams.swift
//  StripePayments
//
//  Created by Nick Porter on 2/21/24.
//

import Foundation

/// An object representing parameters used to create a AmazonPay Payment Method
public class STPPaymentMethodAmazonPayParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    @objc
    public class func rootObjectName() -> String? {
        return "amazon_pay"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
