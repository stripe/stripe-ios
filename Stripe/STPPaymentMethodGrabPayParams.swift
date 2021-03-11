//
//  STPPaymentMethodGrabPayParams.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 7/21/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a GrabPay Payment Method
public class STPPaymentMethodGrabPayParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    public class func rootObjectName() -> String? {
        return "grabpay"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
