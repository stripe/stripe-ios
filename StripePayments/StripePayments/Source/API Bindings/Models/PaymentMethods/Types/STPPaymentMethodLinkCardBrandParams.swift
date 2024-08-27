//
//  STPPaymentMethodLinkCardBrandParams.swift
//  StripePayments
//
//  Created by Mat Schmid on 2024-08-27.
//

import Foundation

public class STPPaymentMethodLinkCardBrandParams: NSObject, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    // MARK: - STPFormEncodable
    @objc
    public class func rootObjectName() -> String? {
        "link_card_brand"
    }

    public static func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        [:]
    }
}
