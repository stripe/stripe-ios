//
//  FinancialConnectionsInstitution.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/6/22.
//

import Foundation
@_spi(STP) import StripeCore

struct FinancialConnectionsInstitution: Decodable, Hashable, Equatable {
    let id: String
    let name: String
    let url: String?
    let smallImageUrl: String? // TODO(kgaidis): this is a fake placeholder until we get real URL's
    
    init(id: String, name: String, url: String?, smallImageUrl: String? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.smallImageUrl = smallImageUrl
    }
}

// MARK: - Institution List

struct FinancialConnectionsInstitutionList: Decodable {
    let data: [FinancialConnectionsInstitution]
    let hasMore: Bool
    let count: Int
}
