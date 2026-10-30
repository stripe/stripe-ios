//
//  STPPaymentMethodCashAppParams.swift
//  StripePayments
//
//  Created by Nick Porter on 12/12/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a CashApp Payment Method
public class STPPaymentMethodCashAppParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    public static func rootObjectName() -> String? {
        return "cashapp"
    }

    public static func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [:]
    }
}
