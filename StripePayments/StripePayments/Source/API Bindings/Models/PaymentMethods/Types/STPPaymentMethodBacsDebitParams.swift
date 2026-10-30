//
//  STPPaymentMethodBacsDebitParams.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 1/29/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// The user's bank account details.
/// - seealso: https://stripe.com/docs/api/payment_methods/create#create_payment_method-bacs_debit
public class STPPaymentMethodBacsDebitParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// The bank account number (eg 00012345)
    public var accountNumber: String?
    /// The sort code of the bank account (eg 10-88-00)
    public var sortCode: String?

    public class func rootObjectName() -> String? {
        return "bacs_debit"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPPaymentMethodBacsDebitParams.sortCode: "sort_code",
            \STPPaymentMethodBacsDebitParams.accountNumber: "account_number",
        ]
    }
}
