//
//  STPPaymentMethodNaverPayParams.swift
//  StripePayments
//
//  Created by Nick Porter on 8/27/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a Naver Pay Payment Method.
public class STPPaymentMethodNaverPayParams: NSObject, STPFormEncodable {
    /// The raw funding source sent to Stripe.
    @objc public var fundingString: String?

    /// Whether to fund the transaction with a card or Naver Pay points.
    @objc public var funding: STPPaymentMethodNaverPayFunding {
        get {
            return STPPaymentMethodNaverPayFunding(string: fundingString)
        }
        set {
            fundingString = newValue.stringValue
        }
    }

    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    @objc public class func rootObjectName() -> String? {
        return "naver_pay"
    }

    @objc public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: fundingString)): "funding",
        ]
    }
}
