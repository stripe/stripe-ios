//
//  STPPaymentMethodAlmaParams.swift
//  StripePayments
//
//  Created by Nick Porter on 3/27/24.
//

import Foundation

/// An object representing parameters used to create a Alma Payment Method
public class STPPaymentMethodAlmaParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    @objc
    public class func rootObjectName() -> String? {
        return "alma"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
