//
//  LinkedAccountList.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 12/21/21.
//

import Foundation
@_spi(STP) import StripeCore

struct LinkedAccountList: StripeDecodable {
    var count: Int?
    var data: [StripeAPI.LinkedAccount]
    /** True if this list has another page of items after this one that can be fetched. */
    var hasMore: Bool
    var totalCount: Int?
    /** The URL where this list can be accessed. */
    var url: String
    var _allResponseFieldsStorage: NonEncodableParameters?

}
