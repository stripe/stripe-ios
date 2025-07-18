//
//  STPIntentAutomaticPaymentMethods.swift
//  StripePayments
//
//  Created by Joyce Qin on 7/16/25.
//

@_spi(STP) public class STPIntentAutomaticPaymentMethods: NSObject {
    public let enabled: Bool
    public var allResponseFields: [AnyHashable: Any]

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
        guard let dict = response else {
            return nil
        }
        let enabled = dict["enabled"] as? Bool ?? false
        return STPIntentAutomaticPaymentMethods(enabled: enabled,
                                                allResponseFields: dict
        ) as? Self
    }
    /// :nodoc:
    public override var description: String {
        let props: [String] = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPIntentAutomaticPaymentMethods.self), self),
            "enabled = \(enabled)",
        ]
        return "<\(props.joined(separator: "; "))>"
    }
}
