//
//  FinancialConnectionsStreamlinedConsent.swift
//  StripeFinancialConnections
//
//  Created by Till Hellmund on 2025-02-05.
//

import Foundation

struct FinancialConnectionsStreamlinedConsent: Decodable {
    let screen: FinancialConnectionsGenericInfoScreen
    let dataAccessNotice: FinancialConnectionsDataAccessNotice?
    let legalDetailsNotice: FinancialConnectionsLegalDetailsNotice
}
