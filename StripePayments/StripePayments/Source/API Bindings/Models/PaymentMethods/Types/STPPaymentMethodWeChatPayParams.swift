//
//  STPPaymentMethodWeChatPayParams.swift
//  StripePayments
//
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a WeChat Pay Payment Method
/// WeChat Pay is currently unavailable in the iOS SDK.
class STPPaymentMethodWeChatPayParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    public class func rootObjectName() -> String? {
        return "wechat_pay"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
