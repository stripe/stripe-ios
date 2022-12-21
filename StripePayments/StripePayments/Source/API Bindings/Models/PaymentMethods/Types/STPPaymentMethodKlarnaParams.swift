//
//  STPPaymentMethodKlarnaParams.swift
//  StripePayments
//
//  Created by Nick Porter on 10/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create an Klarna Payment Method
public class STPPaymentMethodKlarnaParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    @objc
    public static func rootObjectName() -> String? {
        return "klarna"
    }

    @objc
    public static func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
