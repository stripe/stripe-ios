//
//  STPPaymentMethodSEPADebitParams.swift
//  StripePayments
//
//  Created by Cameron Sabol on 10/7/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a SEPA Debit Payment Method
public class STPPaymentMethodSEPADebitParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// The IBAN number for the bank account you wish to debit. Required.
    @objc public var iban: String?

    // MARK: - STPFormEncodable
    public class func rootObjectName() -> String? {
        return "sepa_debit"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: iban)): "iban"
        ]
    }
}
