//
//  STPPaymentMethodCryptoParams.swift
//  StripePayments
//
//  Created by Eric Zhang on 11/20/24.
//

import Foundation

/// An object representing parameters used to create a Crypto Payment Method
public class STPPaymentMethodCryptoParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    public class func rootObjectName() -> String? {
        return "crypto"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
