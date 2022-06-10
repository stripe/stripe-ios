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
}

// MARK: - Institution List

struct FinancialConnectionsInstitutionList: Decodable {
    let data: [FinancialConnectionsInstitution]
    let hasMore: Bool
    let count: Int
}

// MARK: - Institution List

struct FinancialConnectionsInstitutionList: Decodable {
    let data: [FinancialConnectionsInstitution]
    let hasMore: Bool
    let count: Int
}
