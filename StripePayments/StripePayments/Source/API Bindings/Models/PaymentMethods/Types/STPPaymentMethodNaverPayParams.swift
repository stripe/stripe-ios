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
    public var fundingString: String?

    /// Whether to fund the transaction with a card or Naver Pay points.
    public var funding: STPPaymentMethodNaverPayFunding {
        get {
            return STPPaymentMethodNaverPayFunding(string: fundingString)
        }
        set {
            fundingString = newValue.stringValue
        }
    }

    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    public class func rootObjectName() -> String? {
        return "naver_pay"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPPaymentMethodNaverPayParams.fundingString: "funding",
        ]
    }
}
