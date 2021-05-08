//
//  STPPaymentMethodWeChatPayParams.swift
//  StripeiOS
//
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a WeChat Pay Payment Method
public class STPPaymentMethodWeChatPayParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]
    
    @objc
    public class func rootObjectName() -> String? {
        return "wechat_pay"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
