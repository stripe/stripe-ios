//
//  STPIntentActionMultibancoDisplayDetails.swift
//  StripePayments
//
//  Created by Nick Porter on 4/22/24.
//

import Foundation

/// Contains Multibanco details necessary for the customer to complete the payment.
public class STPIntentActionMultibancoDisplayDetails: NSObject, STPAPIResponseDecodable {
    /// The multibanco entity number
    @objc public let entity: String

    /// Multibanco reference number
    @objc public let reference: String

    /// The expiry date of the multibanco voucher.
    @objc public let expiresAt: Date

    /// The URL to the hosted multibanco voucher page, which allows customers to view the multibanco voucher.
    @objc public let hostedVoucherURL: URL

    /// :nodoc:
    public private(set) var allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(
                format: "%@: %p",
                NSStringFromClass(STPIntentActionMultibancoDisplayDetails.self),
                self
            ),
            // MultibancoDisplayDetails
            "entity = \(String(describing: entity))",
            "reference = \(String(describing: reference))",
            "expiresAt = \(String(describing: expiresAt))",
            "hostedVoucherURL = \(String(describing: hostedVoucherURL))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodable

    required init?(dictionary: [AnyHashable: Any]) {
        guard let entity = dictionary.stp_string(forKey: "entity"),
              let reference = dictionary.stp_string(forKey: "reference"),
              let expiresAt = dictionary.stp_date(forKey: "expires_at"),
              let hostedVoucherURL = dictionary.stp_url(forKey: "hosted_voucher_url")
        else {
            return nil
        }

        self.entity = entity
        self.reference = reference
        self.expiresAt = expiresAt
        self.hostedVoucherURL = hostedVoucherURL
        self.allResponseFields = dictionary

        super.init()
    }

    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }

        return self.init(dictionary: response)
    }
}
