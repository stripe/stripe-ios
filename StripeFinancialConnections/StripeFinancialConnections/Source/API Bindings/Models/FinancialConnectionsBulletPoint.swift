//
//  FinancialConnectionsBulletPoint.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/19/23.
//

import Foundation

struct FinancialConnectionsBulletPoint: Decodable {
    let icon: FinancialConnectionsImage?
    let title: String?
    let content: String?

    init(icon: FinancialConnectionsImage, title: String? = nil, content: String? = nil) {
        self.icon = icon
        self.title = title
        self.content = content
    }
}
