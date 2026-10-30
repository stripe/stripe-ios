//
//  STPPaymentMethodAUBECSDebitParams.swift
//  StripePayments
//
//  Created by Cameron Sabol on 3/3/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create an AU BECS Debit Payment Method
public class STPPaymentMethodAUBECSDebitParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// The account number to debit.
    public var accountNumber: String?
    /// Six-digit number identifying bank and branch associated with this bank account.
    public var bsbNumber: String?

    // MARK: - STPFormEncodable
    public class func rootObjectName() -> String? {
        return "au_becs_debit"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPPaymentMethodAUBECSDebitParams.accountNumber: "account_number",
            \STPPaymentMethodAUBECSDebitParams.bsbNumber: "bsb_number",
        ]
    }
}
