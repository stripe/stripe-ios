//
//  STPPaymentMethodAffirmParams.swift
//  StripePayments
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create an Affirm Payment Method
public class STPPaymentMethodAffirmParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    public static func rootObjectName() -> String? {
        return "affirm"
    }

    public static func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [:]
    }
}
