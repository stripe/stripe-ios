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
@_spi(STP) public class STPCardBrandChoice: NSObject {

    /// Determines if this intent is eligible for card brand choice
    public let eligible: Bool

    /// An optional array of preferred card networks
    public let preferredNetworks: [String]?

    /// :nodoc:
    public let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPCardBrandChoice.self), self),
            // Properties
            "eligible = \(String(describing: eligible))",
            "preferredNetworks = \(String(describing: preferredNetworks))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    private init(
        eligible: Bool,
        preferredNetworks: [String]?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.eligible = eligible
        self.preferredNetworks = preferredNetworks
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
            preferredNetworks: dict["preferred_networks"] as? [String],
            allResponseFields: dict
        ) as? Self
    }

}
