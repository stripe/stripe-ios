//
//  STPEmptyStripeResponse.swift
//  StripePayments
//
//  Created by Cameron Sabol on 6/11/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// An STPAPIResponseDecodable implementation to use for endpoints that don't
/// actually return objects, like /v1/3ds2/challenge_completed
@_spi(STP) public class STPEmptyStripeResponse: NSObject, STPAPIResponseDecodable {
    @_spi(STP) public private(set) var allResponseFields: [AnyHashable: Any] = [:]

    required internal override init() {
        super.init()
    }

    @_spi(STP) public class func decodedObject(
        fromAPIResponse response: [AnyHashable: Any]?
    ) -> Self? {
        let emptyResponse = self.init()
        if let response = response {
            emptyResponse.allResponseFields = response
        }

        return emptyResponse
    }
}
