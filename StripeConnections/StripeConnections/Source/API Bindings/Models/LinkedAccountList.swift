//
//  LinkedAccountList.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 12/21/21.
//

import Foundation
@_spi(STP) import StripeCore

struct LinkedAccountList: StripeDecodable {
    let count: Int?
    let data: [StripeAPI.LinkedAccount]
    /** True if this list has another page of items after this one that can be fetched. */
    let hasMore: Bool
    let totalCount: Int?
    /** The URL where this list can be accessed. */
    let url: String
    var _allResponseFieldsStorage: NonEncodableParameters?

}
