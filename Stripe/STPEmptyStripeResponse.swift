//
//  STPEmptyStripeResponse.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 6/11/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// An STPAPIResponseDecodable implementation to use for endpoints that don't
/// actually return objects, like /v1/3ds2/challenge_completed
class STPEmptyStripeResponse: NSObject, STPAPIResponseDecodable {
    private(set) var allResponseFields: [AnyHashable: Any] = [:]

    required internal override init() {
        super.init()
    }

    class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        let emptyResponse = self.init()
        if let response = response {
            emptyResponse.allResponseFields = response
        }

        return emptyResponse
    }
}
