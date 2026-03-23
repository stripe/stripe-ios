//
//  STPPaymentMethodPayByBankParams.swift
//  StripePayments
//
//  Created by Joyce Qin on 3/16/26
//

import Foundation

/// An object representing parameters used to create a Pay by Bank Payment Method
public class STPPaymentMethodPayByBankParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    @objc
    public class func rootObjectName() -> String? {
        return "pay_by_bank"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
