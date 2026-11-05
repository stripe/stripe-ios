//
//  STPPaymentMethodPrzelewy24Params.swift
//  StripePayments
//
//  Created by Vineet Shah on 4/23/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a Przelewy24 Payment Method
public class STPPaymentMethodPrzelewy24Params: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    public class func rootObjectName() -> String? {
        return "p24"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [:]
    }
}
