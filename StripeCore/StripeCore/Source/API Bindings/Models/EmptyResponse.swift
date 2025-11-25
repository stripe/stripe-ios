//
//  EmptyResponse.swift
//  StripeCore
//
//  Created by Jaime Park on 11/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// This is an object representing an empty response from a request.
@_spi(STP) public struct EmptyResponse: UnknownFieldsDecodable {
    public var _allResponseFieldsStorage: NonEncodableParameters?
}
