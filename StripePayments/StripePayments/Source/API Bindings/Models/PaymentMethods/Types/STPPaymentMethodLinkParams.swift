//
//  STPPaymentMethodLinkParams.swift
//  StripePayments
//
//  Created by Cameron Sabol on 8/26/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

/// An object representing parameters used to create an Link Payment Method
public class STPPaymentMethodLinkParams: NSObject, STPFormEncodable {
    /// :nodoc:
    @_spi(InternalOnlyAPI) public var paymentDetailsID: String?

    /// :nodoc:
    @_spi(InternalOnlyAPI) public var credentials: [AnyHashable: Any]?

    /// :nodoc:
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    public class func rootObjectName() -> String? {
        return "link"
    }

    public static func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPPaymentMethodLinkParams.credentials: "credentials",
            \STPPaymentMethodLinkParams.paymentDetailsID: "payment_details_id",
        ]
    }
}
