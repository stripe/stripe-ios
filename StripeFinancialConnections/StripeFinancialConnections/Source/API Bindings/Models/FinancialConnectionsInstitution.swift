//
//  FinancialConnectionsInstitution.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/6/22.
//

import Foundation
@_spi(STP) import StripeCore

struct FinancialConnectionsInstitution: Decodable {
    let featured: Bool
    let featuredOrder: Int?
    let id: String
    let name: String
    let url: String?
}
