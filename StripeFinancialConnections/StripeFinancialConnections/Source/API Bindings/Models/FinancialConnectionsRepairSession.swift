//
//  FinancialConnectionsRepairSession.swift
//  StripeFinancialConnections
//
//  Created by Till Hellmund on 1/27/25.
//

import Foundation

struct FinancialConnectionsRepairSession: Decodable {
    let id: String
    let flow: FinancialConnectionsAuthSession.Flow?
    let url: String?
    let isOauth: Bool?
    let display: FinancialConnectionsAuthSession.Display?
    let institution: FinancialConnectionsInstitution?
}
