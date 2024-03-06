//
//  FinancialConnectionsDataAccessNotice.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/19/23.
//

import Foundation

struct FinancialConnectionsDataAccessNotice: Decodable {
    let icon: FinancialConnectionsImage?
    let title: String
    let connectedAccountNotice: ConnectedAccountNotice?
    let subtitle: String?
    let body: Body
    let disclaimer: String?
    let cta: String

    struct Body: Decodable {
        let bullets: [FinancialConnectionsBulletPoint]
    }

    struct ConnectedAccountNotice: Decodable {
        let subtitle: String
        let body: Body
    }
}
