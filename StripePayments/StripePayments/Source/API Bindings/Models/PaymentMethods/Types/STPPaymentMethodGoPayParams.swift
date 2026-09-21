//
//  STPPaymentMethodGoPayParams.swift
//  StripePayments
//
//  Created by Nick Porter on 9/16/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// An object representing parameters used to create a GoPay Payment Method.
public class STPPaymentMethodGoPayParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    @objc public class func rootObjectName() -> String? {
        return "gopay"
    }

    @objc public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
