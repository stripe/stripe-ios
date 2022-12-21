//
//  STPPaymentMethodCardNetworks.swift
//  StripePayments
//
//  Created by Cameron Sabol on 7/15/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// `STPPaymentMethodCardNetworks` contains information about card networks that can be used to process a payment.
public class STPPaymentMethodCardNetworks: NSObject, STPAPIResponseDecodable {
    private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// All available networks for the card.
    @objc public private(set) var available: [String] = []
    /// The preferred network for the card if one exists.
    @objc public private(set) var preferred: String?

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodCardNetworks.self), self),
            // Properties
            "available: \(available)",
            "preferred: \(preferred ?? "")",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodable
    required init?(
        withDictionary dict: [AnyHashable: Any]
    ) {
        super.init()
        let dict = dict.stp_dictionaryByRemovingNulls()
        guard let available = dict.stp_array(forKey: "available") as? [String] else {
            return nil
        }
        self.available = available
        self.preferred = dict.stp_string(forKey: "preferred")
        self.allResponseFields = dict
    }

    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        return self.init(withDictionary: response)
    }
}
