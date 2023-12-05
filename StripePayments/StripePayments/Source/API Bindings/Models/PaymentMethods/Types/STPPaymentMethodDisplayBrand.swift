//
//  STPPaymentMethodDisplayBrand.swift
//  StripePayments
//
//  Created by Nick Porter on 11/30/23.
//

import Foundation

/// `STPPaymentMethodDisplayBrand` contains information about card's display brand
public class STPPaymentMethodDisplayBrand: NSObject, STPAPIResponseDecodable {
    private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// The display brand for this card
    @objc public private(set) var type: String?

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodDisplayBrand.self), self),
            // Properties
            "type: \(type ?? "")",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodable
    required init?(
        withDictionary dict: [AnyHashable: Any]
    ) {
        super.init()
        let dict = dict.stp_dictionaryByRemovingNulls()
        self.type = dict.stp_string(forKey: "type")
        self.allResponseFields = dict
    }

    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        return self.init(withDictionary: response)
    }
}
