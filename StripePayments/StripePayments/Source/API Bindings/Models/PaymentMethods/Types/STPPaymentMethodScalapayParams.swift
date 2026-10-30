//
//  STPPaymentMethodScalapayParams.swift
//  StripePayments
//
//  Created by Nick Porter on 9/8/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

/// An object representing parameters used to create a Scalapay Payment Method.
public class STPPaymentMethodScalapayParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    public class func rootObjectName() -> String? {
        return "scalapay"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
