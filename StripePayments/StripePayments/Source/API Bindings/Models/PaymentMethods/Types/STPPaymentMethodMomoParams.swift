//
//  STPPaymentMethodMomoParams.swift
//  StripePayments
//
//  Created by Nick Porter on 9/16/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

/// An object representing parameters used to create a MoMo Payment Method.
public class STPPaymentMethodMomoParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    public class func rootObjectName() -> String? {
        return "momo"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
