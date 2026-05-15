//
//  STPPaymentMethodUPIParams.swift
//  StripePayments
//
//  Created by Anirudh Bhargava on 11/6/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a UPI Payment Method
public class STPPaymentMethodUPIParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// Customer’s Virtual Payment Address (VPA). Required.
    @objc public var vpa: String?

    @objc
    public class func rootObjectName() -> String? {
        return "upi"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: vpa)): "vpa"
        ]
    }
}
