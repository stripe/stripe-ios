//
//  ConsumerSession+LookupResponse.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 11/2/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

extension ConsumerSession {
    struct Preferences {
        let publishableKey: String
    }

    class LookupResponse: NSObject, STPAPIResponseDecodable {
        let allResponseFields: [AnyHashable: Any]
        
        enum ResponseType {
            case found(
                consumerSession: ConsumerSession,
                preferences: ConsumerSession.Preferences
            )
            
            // errorMessage can be used internally to differentiate between
            // a not found because of an unrecognized email or a not found
            // due to an invalid cookie
            case notFound(errorMessage: String)
            
            /// Lookup call was not provided an email and no cookies stored
            case noAvailableLookupParams
        }
        
        let responseType: ResponseType
        
        init(_ responseType: ResponseType,
             allResponseFields: [AnyHashable: Any]) {
            self.responseType = responseType
            self.allResponseFields = allResponseFields
            super.init()
        }
        
        static func decodedObject(fromAPIResponse response: [AnyHashable : Any]?) -> Self? {
            guard let response = response,
                  let exists = response["exists"] as? Bool else {
                return nil
            }

            if exists {
                if let consumerSession = ConsumerSession.decodedObject(fromAPIResponse: response),
                   let publishableKey = response["publishable_key"] as? String {
                    return LookupResponse(
                        .found(
                            consumerSession: consumerSession,
                            preferences: .init(publishableKey: publishableKey)
                        ),
                        allResponseFields: response
                    ) as? Self
                } else {
                    return nil
                }
            } else {
                if let errorMessage = response["error_message"] as? String {
                    return LookupResponse(.notFound(errorMessage: errorMessage),
                                          allResponseFields: response) as? Self
                } else {
                    return nil
                }
            }
        }
    }
}
