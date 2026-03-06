//
//  STPPaymentMethodWeroParams.swift
//  StripePayments
//
//  Created by Nick Porter on 3/6/26.
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
