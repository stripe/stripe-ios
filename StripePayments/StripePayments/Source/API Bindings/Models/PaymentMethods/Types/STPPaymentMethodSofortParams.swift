//
//  STPPaymentMethodSofortParams.swift
//  StripePayments
//
//  Created by David Estes on 8/7/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a Sofort Payment Method
public class STPPaymentMethodSofortParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// Two-letter ISO code representing the country the bank account is located in. Required.
    @objc public var country: String?

    @objc
    public class func rootObjectName() -> String? {
        return "sofort"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: country)): "country"
        ]
    }
}
