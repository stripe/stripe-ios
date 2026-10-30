//
//  STPPaymentMethodMobilePayParams.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 10/12/23.
//

import Foundation

/// An object representing parameters used to create a MobilePay Payment Method
public class STPPaymentMethodMobilePayParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    public class func rootObjectName() -> String? {
        return "mobilepay"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [:]
    }
}
