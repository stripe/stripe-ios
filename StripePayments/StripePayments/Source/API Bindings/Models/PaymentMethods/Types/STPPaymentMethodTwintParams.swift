//
//  STPPaymentMethodTwintParams.swift
//  StripePayments
//
//  Copyright © 2024 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a TWINT Payment Method
public class STPPaymentMethodTwintParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    public class func rootObjectName() -> String? {
        return "twint"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
