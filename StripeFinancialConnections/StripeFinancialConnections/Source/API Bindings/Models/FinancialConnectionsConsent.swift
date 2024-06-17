//
//  FinancialConnectionsConsent.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/19/23.
//

import Foundation

struct FinancialConnectionsConsent: Decodable {
    let title: String
    let body: Body
    let aboveCta: String
    let cta: String
    let belowCta: String?

    let dataAccessNotice: FinancialConnectionsDataAccessNotice?
    let legalDetailsNotice: FinancialConnectionsLegalDetailsNotice

    struct Body: Decodable {
        let bullets: [FinancialConnectionsBulletPoint]
    }
}
