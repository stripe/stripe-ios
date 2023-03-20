//
//  STPPaymentMethodAfterpayClearpayParams.swift
//  StripeiOS
//
//  Created by Ali Riaz on 1/12/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create an AfterpayClearpay Payment Method
public class STPPaymentMethodAfterpayClearpayParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    @objc
    public static func rootObjectName() -> String? {
        return "afterpay_clearpay"
    }

    @objc
    public static func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
