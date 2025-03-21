//
//  FinancialConnectionsSelectInstitution.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-03-07.
//

import Foundation

struct FinancialConnectionsSelectInstitution: Decodable {
    let manifest: FinancialConnectionsSessionManifest
    let text: Text?
}

struct Text: Decodable {
    let idConsentContentPane: FinancialConnectionsIDConsentContent
}
