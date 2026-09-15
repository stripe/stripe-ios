//
//  STPPaymentMethodACSSDebitParams.swift
//  StripePayments
//
//  Created by Nick Porter on 8/27/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create an ACSS Debit Payment Method.
public class STPPaymentMethodACSSDebitParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// The account number to debit.
    @objc public var accountNumber: String?
    /// The three-digit institution number for this bank account.
    @objc public var institutionNumber: String?
    /// The five-digit transit number for this bank account.
    @objc public var transitNumber: String?

    // MARK: - STPFormEncodable

    public class func rootObjectName() -> String? {
        return "acss_debit"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: accountNumber)): "account_number",
            NSStringFromSelector(#selector(getter: institutionNumber)): "institution_number",
            NSStringFromSelector(#selector(getter: transitNumber)): "transit_number",
        ]
    }
}
