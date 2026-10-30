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
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// The customer’s bank.
    public var bankName: String?

    // MARK: - STPFormEncodable
    public class func rootObjectName() -> String? {
        return "ideal"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPPaymentMethodiDEALParams.bankName: "bank"
        ]
    }
}
