//
//  FinancialConnectionsInstitutionSearchResultResource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 3/23/23.
//

import Foundation

struct FinancialConnectionsInstitutionSearchResultResource: Decodable {
    let data: [FinancialConnectionsInstitution]
    let showManualEntry: Bool
}
