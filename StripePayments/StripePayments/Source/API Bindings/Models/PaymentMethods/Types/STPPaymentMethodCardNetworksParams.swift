//
//  STPPaymentMethodCardNetworksParams.swift
//  StripePayments
//
//  Created by Nick Porter on 9/28/23.
//

import Foundation

public class STPPaymentMethodCardNetworksParams: NSObject, STPFormEncodable {

    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// The network that your user selected for this payment
    /// method. This must reflect an explicit user choice. If your user didn't
    /// make a selection, then pass `null`.
    public var preferred: String?

    public convenience init(preferred: String?) {
        self.init()
        self.preferred = preferred
    }

    // MARK: - Description
    /// :nodoc:
    public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodCardNetworksParams.self), self),
            // Preferred
            "preferred = \(preferred ?? "")",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPFormEncodable

    public class func rootObjectName() -> String? {
        return "networks"
    }

    public static func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPPaymentMethodCardNetworksParams.preferred: "preferred",
        ]
    }
}
