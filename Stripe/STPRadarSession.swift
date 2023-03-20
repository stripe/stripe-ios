//
//  STPRadarSession.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 5/20/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/**
 A [Radar Session](https://stripe.com/docs/radar/radar-session).
 - Note: This API and the guide linked above require special permissions to use. Contact support@stripe.com if you're interested.
 */
public final class STPRadarSession: NSObject, STPAPIResponseDecodable {
    /// The Stripe identifier of the RadarSession
    @objc public let id: String
    @objc public let allResponseFields: [AnyHashable: Any]

    init(id: String, allResponseFields: [AnyHashable: Any]) {
        self.id = id
        self.allResponseFields = allResponseFields
        super.init()
    }

    public static func decodedObject(fromAPIResponse response: [AnyHashable : Any]?) -> STPRadarSession? {
        guard let response = response else { return nil }
        let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary
        guard let id = dict.stp_string(forKey: "id") else {
            return nil
        }
        
        return STPRadarSession(id: id, allResponseFields: response)
    }
}
