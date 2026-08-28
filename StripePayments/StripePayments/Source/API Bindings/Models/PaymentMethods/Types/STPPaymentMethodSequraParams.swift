//
//  STPPaymentMethodSequraParams.swift
//  StripePayments
//
//  Created by Nick Porter on 8/28/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a SeQura Payment Method.
public class STPPaymentMethodSequraParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    @objc public class func rootObjectName() -> String? {
        return "sequra"
    }

    @objc public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
