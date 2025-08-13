//
//  STPPaymentMethodPaperCheckParams.swift
//  StripePayments
//
//  Created by Martin Gordon on 8/7/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create an Paper Check Payment Method
public class STPPaymentMethodPaperCheckParams: NSObject, STPFormEncodable {
    
    /// The token of the US Paper Check object. Required.
    @objc public var token: String?
    
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    @objc
    public class func rootObjectName() -> String? {
        return "paper_check"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [NSStringFromSelector(#selector(getter: token)): "token"]
    }
}
