//
//  STPIntentActionOXXODisplayDetails.swift
//  Stripe
//
//  Created by Polo Li on 6/23/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// Contains OXXO details necessary for the customer to complete the payment.
public class STPIntentActionOXXODisplayDetails: NSObject, STPAPIResponseDecodable {
    /// The timestamp after which the OXXO voucher expires.
    @objc public let expiresAfter: Date

    /// The URL for the hosted OXXO voucher page, which allows customers to view and print an OXXO voucher.
    @objc public let hostedVoucherURL: URL

    /// OXXO reference number.
    @objc public let number: String

    internal init(
        expiresAfter: Date,
        hostedVoucherURL: URL,
        number: String,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.expiresAfter = expiresAfter
        self.hostedVoucherURL = hostedVoucherURL
        self.number = number
        self.allResponseFields = allResponseFields
        super.init()
    }

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(
                format: "%@: %p", NSStringFromClass(STPIntentActionOXXODisplayDetails.self), self),
            // OXXODisplayDetails
            "expiresAfter = \(String(describing: expiresAfter))",
            "hostedVoucherURL = \(String(describing: hostedVoucherURL))",
            "number = \(String(describing: number))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response, let nsDict = response as NSDictionary?,
            let expiresAfter = nsDict.stp_date(forKey: "expires_after"),
            let hostedVoucherURL = nsDict.stp_url(forKey: "hosted_voucher_url"),
            let number = nsDict.stp_string(forKey: "number")
        else {
            return nil
        }

        return STPIntentActionOXXODisplayDetails(
            expiresAfter: expiresAfter,
            hostedVoucherURL: hostedVoucherURL,
            number: number,
            allResponseFields: dict) as? Self
    }

    public private(set) var allResponseFields: [AnyHashable: Any]
}
