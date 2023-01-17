//
//  STPIntentActionVerifyWithMicrodeposits.swift
//  StripePayments
//
//  Created by Cameron Sabol on 2/23/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

@objc public enum STPMicrodepositType: Int {

    /// This is an unknown type that's been added since the SDK
    /// was last updated.
    /// Update your SDK, or use the `allResponseFields`
    /// for custom handling.
    case unknown

    /// Two non-unique micro-deposits to the customer's bank account
    case amounts

    /// A single micro-deposit sent to the customer's bank account with a unique descriptor code
    case descriptorCode

    internal init(
        string: String
    ) {
        switch string.lowercased() {
        case "amounts":
            self = .amounts
        case "descriptor_code":
            self = .descriptorCode
        default:
            self = .unknown
        }
    }
}

/// Contains details describing microdeposits verification flow for US Bank Accounts.
public class STPIntentActionVerifyWithMicrodeposits: NSObject {

    /// The timestamp when the microdeposits are expected to land
    @objc public let arrivalDate: Date

    /// The URL for the hosted verification page, which allows customers to verify their bank account
    @objc public let hostedVerificationURL: URL

    /// The type of the microdeposit sent to the customer. Used to distinguish between different verificaion methods.
    @objc public let microdepositType: STPMicrodepositType

    /// :nodoc:
    @objc public let allResponseFields: [AnyHashable: Any]

    internal init(
        arrivalDate: Date,
        hostedVerificationURL: URL,
        microdepositType: STPMicrodepositType,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.arrivalDate = arrivalDate
        self.hostedVerificationURL = hostedVerificationURL
        self.microdepositType = microdepositType
        self.allResponseFields = allResponseFields
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable
/// :nodoc:
extension STPIntentActionVerifyWithMicrodeposits: STPAPIResponseDecodable {
    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response,
            let arrivalDate = response.stp_date(forKey: "arrival_date"),
            let hostedVerificationURL = response.stp_url(forKey: "hosted_verification_url"),
            let microdepositTypeString = response.stp_string(forKey: "microdeposit_type")
        else {
            return nil
        }

        return STPIntentActionVerifyWithMicrodeposits(
            arrivalDate: arrivalDate,
            hostedVerificationURL: hostedVerificationURL,
            microdepositType: STPMicrodepositType(string: microdepositTypeString),
            allResponseFields: response
        ) as? Self
    }

}
