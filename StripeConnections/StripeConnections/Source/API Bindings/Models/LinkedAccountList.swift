//
//  LinkedAccountList.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 12/21/21.
//

import Foundation
@_spi(STP) import StripeCore

public extension StripeAPI {

    struct LinkedAccountList {
        public let data: [StripeAPI.LinkedAccount]
        /** True if this list has another page of items after this one that can be fetched. */
        public let hasMore: Bool
        @_spi(STP) public var _allResponseFieldsStorage: NonEncodableParameters?

        // MARK: - Internal Init

        internal init(data: [StripeAPI.LinkedAccount],
                      hasMore: Bool) {
            self.data = data
            self.hasMore = hasMore
        }
    }
}

// MARK: - StripeDecodable

@_spi(STP) extension StripeAPI.LinkedAccountList: StripeDecodable {}
