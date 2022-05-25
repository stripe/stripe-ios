//
//  STPPaymentMethodLinkParams.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 8/26/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

/// An object representing parameters used to create an Link Payment Method
public class STPPaymentMethodLinkParams: NSObject, STPFormEncodable {
    /// :nodoc:
    @objc var paymentDetailsID: String?

    /// :nodoc:
    @objc var credentials: [AnyHashable: Any]?

    /// :nodoc:
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    @objc
    public class func rootObjectName() -> String? {
        return "link"
    }

    @objc
    public static func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter:credentials)): "credentials",
            NSStringFromSelector(#selector(getter:paymentDetailsID)): "payment_details_id",
        ]
    }
}
