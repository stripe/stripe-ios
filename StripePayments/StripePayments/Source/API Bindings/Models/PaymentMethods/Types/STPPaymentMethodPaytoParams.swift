// Copyright © 2026 Stripe, Inc. All rights reserved.

import Foundation

/// Bank details for a PayTo PaymentMethod. Supply either a PayID or a BSB and account number.
public class STPPaymentMethodPaytoParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]
    /// The bank account number.
    @objc public var accountNumber: String?
    /// The six-digit Australian bank and branch code.
    @objc public var bsbNumber: String?
    /// The email address or phone number registered as a PayID.
    @objc public var payId: String?

    @objc public class func rootObjectName() -> String? { "payto" }

    @objc public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        [
            NSStringFromSelector(#selector(getter: accountNumber)): "account_number",
            NSStringFromSelector(#selector(getter: bsbNumber)): "bsb_number",
            NSStringFromSelector(#selector(getter: payId)): "pay_id",
        ]
    }
}
