//
//  FinancialConnectionsAuthRepairSession.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/26/23.
//

import Foundation

struct FinancialConnectionsAuthRepairSession: Decodable {
    let id: String
    let url: String
    let institution: FinancialConnectionsInstitution
    
    //flow: AuthSessionFlow;
    //display?: AuthSessionDisplay;
    //partner_institution_token?: string | null | undefined;
    //used_abstract?: boolean;
    //is_oauth?: boolean;
}
