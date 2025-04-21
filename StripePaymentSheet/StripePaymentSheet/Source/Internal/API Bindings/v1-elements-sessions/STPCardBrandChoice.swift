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

    /// List of preferred networks
    let preferredNetworks: [String]

    /// Dictionary indicating if a merchant can process each cobranded network
    let supportedCobrandedNetworks: [String: Bool]

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

   required init(
        eligible: Bool,
        preferredNetworks: [String],
        supportedCobrandedNetworks: [String: Bool],
        allResponseFields: [AnyHashable: Any]
    ) {
        self.eligible = eligible
        self.preferredNetworks = preferredNetworks
        self.supportedCobrandedNetworks = supportedCobrandedNetworks
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
            preferredNetworks: dict["preferred_networks"] as? [String] ?? [],
            supportedCobrandedNetworks: dict["supported_cobranded_networks"] as? [String: Bool] ?? [:],
            allResponseFields: dict
        ) as? Self
    }
}
