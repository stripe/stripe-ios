//
//  STPPaymentMethodFPX.swift
//  Stripe
//
//  Created by David Estes on 7/30/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// An FPX Payment Method.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-fpx
public class STPPaymentMethodFPX: NSObject, STPAPIResponseDecodable {
    /// The customer’s bank identifier code.
    @objc public private(set) var bankIdentifierCode: String?
    private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodFPX.self), self),
            // Properties
            "bank: \(bankIdentifierCode ?? "")",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    override required init() {
        super.init()
    }

    // MARK: - STPAPIResponseDecodable
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary

        let fpx = self.init()
        fpx.allResponseFields = response
        fpx.bankIdentifierCode = dict.stp_string(forKey: "bank")
        return fpx
    }
}
