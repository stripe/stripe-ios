//
//  STPPaymentMethodPayByBankParams.swift
//  StripePayments
//
//  Created by Joyce Qin on 3/16/26
//

import Foundation

/// An object representing parameters used to create a Pay by Bank Payment Method
public class STPPaymentMethodPayByBankParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// The bank identifier (e.g. "uk_hsbc"). This is included in the params if bank selection happens prior to tokenization. If not provided, the bank can be selected later in the flow.
    @objc public var bank: String?

    // MARK: - STPFormEncodable
    public class func rootObjectName() -> String? {
        return "pay_by_bank"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: bank)): "bank",
        ]
    }
}
