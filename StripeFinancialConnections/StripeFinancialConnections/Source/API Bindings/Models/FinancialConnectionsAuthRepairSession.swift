//
//  FinancialConnectionsAuthRepairSession.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/26/23.
//

import Foundation

struct FinancialConnectionsAuthRepairSession: Decodable {
    let id: String
    let flow: FinancialConnectionsAuthSession.Flow
    let url: String
    let isOauth: Bool
    let institution: FinancialConnectionsInstitution
    let display: FinancialConnectionsAuthSession.Display

    // partner_institution_token?: string | null | undefined;
    // used_abstract?: boolean;
}
