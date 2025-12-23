//
//  STPPaymentMethodEPSParams.swift
//  StripePayments
//
//  Created by Shengwei Wu on 5/14/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a EPS Payment Method
public class STPPaymentMethodEPSParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// The customer's bank.
    @objc public var bank: String?

    // MARK: - STPFormEncodable
    @objc
    public class func rootObjectName() -> String? {
        return "eps"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: bank)): "bank"
        ]
    }
}
