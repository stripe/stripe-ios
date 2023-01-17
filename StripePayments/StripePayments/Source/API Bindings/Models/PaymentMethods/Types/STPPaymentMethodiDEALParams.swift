//
//  STPPaymentMethodiDEALParams.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create an iDEAL Payment Method
public class STPPaymentMethodiDEALParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// The customer’s bank.
    @objc public var bankName: String?

    // MARK: - STPFormEncodable
    @objc
    public class func rootObjectName() -> String? {
        return "ideal"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: bankName)): "bank"
        ]
    }
}
