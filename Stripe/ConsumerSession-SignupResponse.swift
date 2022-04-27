//
//  ConsumerSession-SignupResponse.swift
//  StripeiOS
//
//  Created by Ramon Torres on 4/22/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

extension ConsumerSession {

    class SignupResponse: NSObject, STPAPIResponseDecodable {
        let consumerSession: ConsumerSession

        let preferences: ConsumerSession.Preferences

        let allResponseFields: [AnyHashable: Any]

        init(
            consumerSession: ConsumerSession,
            preferences: ConsumerSession.Preferences,
            allResponseFields: [AnyHashable: Any]
        ) {
            self.consumerSession = consumerSession
            self.preferences = preferences
            self.allResponseFields = allResponseFields
            super.init()
        }

        static func decodedObject(fromAPIResponse response: [AnyHashable : Any]?) -> Self? {
            guard
                let response = response,
                let consumerSession = ConsumerSession.decodedObject(fromAPIResponse: response),
                let publishableKey = response["publishable_key"] as? String
            else {
                return nil
            }

            return SignupResponse(
                consumerSession: consumerSession,
                preferences: Preferences(publishableKey: publishableKey),
                allResponseFields: response
            ) as? Self
        }
    }

}
