//
//  FinancialConnectionsStreamlinedConsent.swift
//  StripeFinancialConnections
//
//  Created by Till Hellmund on 1/20/25.
//

import Foundation

struct FinancialConnectionsStreamlinedConsent: Decodable {
    let screen: FinancialConnectionsGenericInfoScreen
    let moreInfoNotice: FinancialConnectionsGenericInfoScreen
    let dataAccessNotice: FinancialConnectionsDataAccessNotice?
    let legalDetailsNotice: FinancialConnectionsLegalDetailsNotice
}
