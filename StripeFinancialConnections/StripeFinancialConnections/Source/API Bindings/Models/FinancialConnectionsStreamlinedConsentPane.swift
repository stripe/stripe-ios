//
//  FinancialConnectionsStreamlinedConsentPane.swift
//  StripeFinancialConnections
//
//  Created by Till Hellmund on 2026-11-05.
//

import Foundation

struct FinancialConnectionsStreamlinedConsentPane: Decodable {
    let screen: FinancialConnectionsGenericInfoScreen
    let dataAccessNotice: FinancialConnectionsDataAccessNotice?
    let legalDetailsNotice: FinancialConnectionsLegalDetailsNotice
    let moreInfoNotice: FinancialConnectionsGenericInfoScreen?
}
