//
//  STPPaymentMethodBLIKParams.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 3/10/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a BLIK Payment Method
/// There are currently no parameters to pass.
/// - seealso: https://site-admin.stripe.com/docs/api/payment_methods/create#create_payment_method-blik
@objc
public class STPPaymentMethodBLIKParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    @objc
    public class func rootObjectName() -> String? {
        return "blik"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
