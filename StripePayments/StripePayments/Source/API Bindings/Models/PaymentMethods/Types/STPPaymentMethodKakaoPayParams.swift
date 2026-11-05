//
//  STPPaymentMethodKakaoPayParams.swift
//  StripePayments
//
//  Created by Nick Porter on 8/27/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a Kakao Pay Payment Method.
public class STPPaymentMethodKakaoPayParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    public class func rootObjectName() -> String? {
        return "kakao_pay"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [:]
    }
}
