//
//  FinancialConnectionsIDContentConsent.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-03-10.
//

import Foundation

struct FinancialConnectionsIDContentConsent: Decodable {
    let screen: FinancialConnectionsGenericInfoScreen
    let legalDetailsNotice: FinancialConnectionsLegalDetailsNotice
}
