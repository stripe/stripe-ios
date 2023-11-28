//
//  STPCardBrandChoice.swift
//  StripePayments
//
//  Created by Nick Porter on 8/29/23.
//

import Foundation

/// Card brand choice information for an intent
/// You cannot directly instantiate an `STPCardBrandChoice`.
/// - seealso: https://stripe.com/docs/card-brand-choice
class STPCardBrandChoice: NSObject {

    /// Determines if this intent is eligible for card brand choice
    let eligible: Bool

    /// :nodoc:
    let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    @objc override var description: String {
        let props: [String] = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPCardBrandChoice.self), self),
            // Properties
            "eligible = \(String(describing: eligible))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    private init(
        eligible: Bool,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.eligible = eligible
        self.allResponseFields = allResponseFields
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable
extension STPCardBrandChoice: STPAPIResponseDecodable {

    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response else {
            return nil
        }

        return STPCardBrandChoice(
            eligible: dict["eligible"] as? Bool ?? false,
            allResponseFields: dict
        ) as? Self
    }

}
