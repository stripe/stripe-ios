//
//  FinancialConnectionsNetworkingLinkSignup.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 3/28/23.
//

import Foundation

struct FinancialConnectionsNetworkingLinkSignup: Decodable {
    let title: String
    let body: Body
    let aboveCta: String
    let cta: String
    let skipCta: String
    let legalDetailsNotice: FinancialConnectionsLegalDetailsNotice?

    struct Body: Decodable {
        let bullets: [FinancialConnectionsBulletPoint]
    }
}
