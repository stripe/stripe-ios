//
//  STPPaymentMethodPayPalParams.swift
//  StripePayments
//
//  Created by Cameron Sabol on 10/5/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a PayPal Payment Method :nodoc:
public class STPPaymentMethodPayPalParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    public class func rootObjectName() -> String? {
        return "paypal"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
