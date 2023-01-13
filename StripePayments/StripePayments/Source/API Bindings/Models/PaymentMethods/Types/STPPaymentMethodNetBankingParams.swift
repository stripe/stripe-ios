//
//  STPPaymentMethodNetBankingParams.swift
//  StripePayments
//
//  Created by Anirudh Bhargava on 11/19/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a NetBanking Payment Method
public class STPPaymentMethodNetBankingParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// Customer’s Bank Name. Required.
    @objc public var bank: String?

    @objc
    public class func rootObjectName() -> String? {
        return "netbanking"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: bank)): "bank"
        ]
    }
}
