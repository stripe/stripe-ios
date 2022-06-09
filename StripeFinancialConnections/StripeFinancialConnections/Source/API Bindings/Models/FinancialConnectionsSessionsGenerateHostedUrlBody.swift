//
// FinancialConnectionsSessionsGenerateHostedUrlBody.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 11/17/21.
//

import Foundation
@_spi(STP) import StripeCore

struct FinancialConnectionsSessionsGenerateHostedUrlBody: Encodable {
    let clientSecret: String
    let fullscreen: Bool
    let hideCloseButton: Bool
}

struct FinancialConnectionsSessionsClientSecretBody: Encodable {
    let clientSecret: String
}
