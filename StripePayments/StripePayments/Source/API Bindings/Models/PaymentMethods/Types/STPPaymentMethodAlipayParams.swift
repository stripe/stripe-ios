//
//  STPPaymentMethodAlipayParams.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 5/14/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create an Alipay Payment Method.
/// There are currently no parameters to pass.
/// - seealso: https://site-admin.stripe.com/docs/api/payment_methods/create#create_payment_method-alipay
public class STPPaymentMethodAlipayParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    public class func rootObjectName() -> String? {
        return "alipay"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [:]
    }
}
