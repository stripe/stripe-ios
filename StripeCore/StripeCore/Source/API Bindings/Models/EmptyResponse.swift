//
//  EmptyResponse.swift
//  StripeCore
//
//  Created by Jaime Park on 11/19/21.
//

import Foundation

/// This is an object representing an empty response from a request
@_spi(STP) public struct EmptyResponse: StripeDecodable {
    public var _allResponseFieldsStorage: NonEncodableParameters?
}

