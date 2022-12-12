//
//  STPIntentActionBoletoDisplayDetails.swift
//  StripePayments
//
//  Created by Ramon Torres on 9/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// Contains Boleto details necessary for the customer to complete the payment.
public class STPIntentActionBoletoDisplayDetails: NSObject, STPAPIResponseDecodable {
    /// The boleto voucher number.
    @objc public let number: String

    /// The expiry date of the boleto voucher.
    @objc public let expiresAt: Date

    /// The URL to the hosted boleto voucher page, which allows customers to view the boleto voucher.
    @objc public let hostedVoucherURL: URL

    /// :nodoc:
    public private(set) var allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(
                format: "%@: %p",
                NSStringFromClass(STPIntentActionBoletoDisplayDetails.self),
                self
            ),
            // BoletoDisplayDetails
            "number = \(String(describing: number))",
            "expiresAt = \(String(describing: expiresAt))",
            "hostedVoucherURL = \(String(describing: hostedVoucherURL))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodable

    required init?(dictionary: [AnyHashable: Any]) {
        guard let number = dictionary.stp_string(forKey: "number"),
              let expiresAt = dictionary.stp_date(forKey: "expires_at"),
              let hostedVoucherURL = dictionary.stp_url(forKey: "hosted_voucher_url")
        else {
            return nil
        }

        self.number = number
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
