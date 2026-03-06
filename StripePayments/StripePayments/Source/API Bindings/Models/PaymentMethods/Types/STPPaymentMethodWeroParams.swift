//
//  STPPaymentMethodWeroParams.swift
//  StripePayments
//

import Foundation

/// An object representing parameters used to create a Wero Payment Method
public class STPPaymentMethodWeroParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    @objc
    public class func rootObjectName() -> String? {
        return "wero"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
