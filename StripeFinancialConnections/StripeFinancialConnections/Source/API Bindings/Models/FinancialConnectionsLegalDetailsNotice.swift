//
//  FinancialConnectionsLegalDetailsNotice.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/19/23.
//

import Foundation

struct FinancialConnectionsLegalDetailsNotice: Decodable {

    let icon: FinancialConnectionsImage?
    let title: String
    let subtitle: String?
    let body: Body
    let disclaimer: String?
    let cta: String

    struct Body: Decodable {
        let links: [Link]

        struct Link: Decodable {
            let title: String
            let content: String?
        }
    }
}
