//
//  STPIntentAutomaticPaymentMethods.swift
//  StripePayments
//
//  Created by Joyce Qin on 7/23/25.
//

import Foundation

/// Automatic payment methods configuration for `STPPaymentIntent` and `STPSetupIntent`.
@_spi(STP) public class STPIntentAutomaticPaymentMethods: NSObject {

    public let enabled: Bool
    public let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPIntentAutomaticPaymentMethods.self), self),
            // Type
            "enabled = \(enabled)",
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    internal init(
        enabled: Bool,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.enabled = enabled
        self.allResponseFields = allResponseFields
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable
extension STPIntentAutomaticPaymentMethods: STPAPIResponseDecodable {

    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
            let enabled = dict["enabled"] as? Bool
        else {
            return nil
        }

        return STPIntentAutomaticPaymentMethods(
            enabled: enabled,
            allResponseFields: dict
        ) as? Self
    }

}
