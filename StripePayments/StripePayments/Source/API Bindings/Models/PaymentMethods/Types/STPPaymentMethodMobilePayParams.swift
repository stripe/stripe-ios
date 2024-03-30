//
//  STPPaymentMethodMobilePayParams.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 10/12/23.
//

import Foundation

/// An object representing parameters used to create a MobilePay Payment Method
public class STPPaymentMethodMobilePayParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    @objc
    public class func rootObjectName() -> String? {
        return "mobilepay"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
