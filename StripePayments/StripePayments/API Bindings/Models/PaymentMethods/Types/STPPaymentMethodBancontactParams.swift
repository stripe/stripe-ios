//
//  STPPaymentMethodBancontactParams.swift
//  StripePayments
//
//  Created by Vineet Shah on 4/29/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a Bancontact Payment Method
public class STPPaymentMethodBancontactParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    public class func rootObjectName() -> String? {
        return "bancontact"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
}
