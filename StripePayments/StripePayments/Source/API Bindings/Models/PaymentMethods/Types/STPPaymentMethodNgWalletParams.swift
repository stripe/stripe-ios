//
//  STPPaymentMethodNgWalletParams.swift
//  StripePayments
//
//  Created by Nick Porter on 9/16/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// An object representing parameters used to create a Naira Wallet Payment Method.
public class STPPaymentMethodNgWalletParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    @objc public class func rootObjectName() -> String? {
        return "ng_wallet"
    }

    @objc public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
