//
//  FinancialConnectionsAccountList.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 12/21/21.
//

import Foundation
@_spi(STP) import StripeCore

public extension StripeAPI {

    struct FinancialConnectionsAccountList {
        public let data: [StripeAPI.FinancialConnectionsAccount]
        /** True if this list has another page of items after this one that can be fetched. */
        public let hasMore: Bool

        // MARK: - Internal Init

        internal init(data: [StripeAPI.FinancialConnectionsAccount],
                      hasMore: Bool) {
            self.data = data
            self.hasMore = hasMore
        }
    }
}

// MARK: - Decodable

@_spi(STP) extension StripeAPI.FinancialConnectionsAccountList: Decodable {}
