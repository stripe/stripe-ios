//
//  STPIntentActionKonbiniDisplayDetails.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 9/12/23.
//

import Foundation

/// Contains Konbini details necessary for the customer to complete the payment.
public class STPIntentActionKonbiniDisplayDetails: NSObject, STPAPIResponseDecodable {
    /// The date at which the pending Konbini payment expires.
    @objc public let expiresAt: Date

    /// The URL for the Konbini payment instructions page, which allows customers to view and print a Konbini voucher.
    @objc public let hostedVoucherURL: URL

    internal init(
        expiresAt: Date,
        hostedVoucherURL: URL,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.expiresAt = expiresAt
        self.hostedVoucherURL = hostedVoucherURL
        self.allResponseFields = allResponseFields
        super.init()
    }

    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
            let expiresAt = dict.stp_date(forKey: "expires_at"),
            let hostedVoucherURL = dict.stp_url(forKey: "hosted_voucher_url")
        else {
            return nil
        }

        return STPIntentActionKonbiniDisplayDetails(
            expiresAt: expiresAt,
            hostedVoucherURL: hostedVoucherURL,
            allResponseFields: dict
        ) as? Self
    }

    public private(set) var allResponseFields: [AnyHashable: Any]
}
