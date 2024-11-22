//
//  STPPaymentMethodCryptoParams.swift
//  StripePayments
//
//  Created by Eric Zhang on 11/20/24.
//

import Foundation

/// An object representing parameters used to create a Crypto Payment Method
public class STPPaymentMethodCryptoParams: NSObject, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    @objc
    public class func rootObjectName() -> String? {
        return "crypto"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
