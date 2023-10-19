//
//  PaymentAccount+Extensions.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 10/17/23.
//

import Foundation

extension StripeAPI.FinancialConnectionsSession.PaymentAccount {

    var isManualEntry: Bool {
        switch self {
        case .bankAccount:
            return true
        default:
            return false
        }
    }
}
