//
//  FinancialConnectionsLegalDetailsNotice.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/19/23.
//

import Foundation

struct FinancialConnectionsLegalDetailsNotice: Decodable {
    let title: String
    let body: Body
    let learnMore: String
    let cta: String

    struct Body: Decodable {
        let bullets: [FinancialConnectionsBulletPoint]
    }
}
