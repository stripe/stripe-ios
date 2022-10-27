//
//  FinancialConnectionsMixedOAuthParams.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 10/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

struct FinancialConnectionsMixedOAuthParams: Decodable {
    let state: String
    let code: String?
    let status: String?
    let memberGuid: String?
    let error: String?
}
