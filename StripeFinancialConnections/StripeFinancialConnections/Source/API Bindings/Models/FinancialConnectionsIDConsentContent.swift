//
//  FinancialConnectionsIDConsentContent.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-03-10.
//

import Foundation

struct FinancialConnectionsIDConsentContent: Decodable {
    let screen: FinancialConnectionsGenericInfoScreen
    let legalDetailsNotice: FinancialConnectionsLegalDetailsNotice
}
