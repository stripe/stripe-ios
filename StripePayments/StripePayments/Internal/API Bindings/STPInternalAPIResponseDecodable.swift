//
//  STPInternalAPIResponseDecodable.swift
//  Stripe
//
//  Created by Ben Guo on 5/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation

/// Objects that can be returned as part of a heterogenous API response
/// (e.g. cards and sources) should implement this protocol.
@objc protocol STPInternalAPIResponseDecodable: STPAPIResponseDecodable {
    /// The object's type. This should match the `object` field in the API response.
    func stripeObject() -> String
}
