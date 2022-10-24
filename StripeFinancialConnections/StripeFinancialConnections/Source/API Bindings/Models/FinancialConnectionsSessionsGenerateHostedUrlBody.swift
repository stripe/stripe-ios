//
// FinancialConnectionsSessionsGenerateHostedUrlBody.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 11/17/21.
//

import Foundation
@_spi(STP) import StripeCore

struct FinancialConnectionsSessionsClientSecretBody: Encodable {
    let clientSecret: String
}
