//
//  STPPaymentMethodAffirmParams.swift
//  StripePayments
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create an Affirm Payment Method
public class STPPaymentMethodAffirmParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    @objc
    public static func rootObjectName() -> String? {
        return "affirm"
    }

    @objc
    public static func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
