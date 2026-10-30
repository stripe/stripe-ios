//
//  STPPaymentMethodLink.swift
//  StripePayments
//
//  Created by Cameron Sabol on 7/6/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// A Link Payment Method.
public class STPPaymentMethodLink: NSObject, STPAPIResponseDecodable {

    public private(set) var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - Description

    /// :nodoc:
    public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodLink.self), self)
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodable
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        return self.init(dictionary: response)
    }

    required init(
        dictionary dict: [AnyHashable: Any]
    ) {
        super.init()
        allResponseFields = dict
    }
}
