//
//  STPPaymentMethodThreeDSecureUsage.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// Contains details on how an `STPPaymentMethodCard` maybe be used for 3D Secure authentication.
public class STPPaymentMethodThreeDSecureUsage: NSObject, STPAPIResponseDecodable {
    /// `YES` if 3D Secure is supported on this card.
    @objc public private(set) var supported = false
    private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(
                format: "%@: %p",
                NSStringFromClass(STPPaymentMethodThreeDSecureUsage.self),
                self
            ),
            // Properties
            "supported: \(supported ? "YES" : "NO")",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodable
    override required init() {
        super.init()
    }

    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {

        guard let response = response else {
            return nil
        }
        let dict = response.stp_dictionaryByRemovingNulls()
        if dict["supported"] == nil {
            return nil
        }

        let usage = self.init()
        usage.allResponseFields = response
        usage.supported = dict.stp_bool(forKey: "supported", or: false)
        return usage
    }
}
