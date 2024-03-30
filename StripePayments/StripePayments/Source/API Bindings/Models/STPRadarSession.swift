//
//  STPRadarSession.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 5/20/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// A [Radar Session](https://stripe.com/docs/radar/radar-session).
public final class STPRadarSession: NSObject, STPAPIResponseDecodable {
    /// The Stripe identifier of the RadarSession
    @objc public let id: String
    @objc public let allResponseFields: [AnyHashable: Any]

    init(
        id: String,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.id = id
        self.allResponseFields = allResponseFields
        super.init()
    }

    public static func decodedObject(
        fromAPIResponse response: [AnyHashable: Any]?
    ) -> STPRadarSession? {
        guard let response = response else { return nil }
        let dict = response.stp_dictionaryByRemovingNulls()
        guard let id = dict.stp_string(forKey: "id") else {
            return nil
        }

        return STPRadarSession(id: id, allResponseFields: response)
    }
}
