//
//  SetCollectMobileFinancialConnectionsResultSender.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/17/24.
//
@_spi(STP) import StripeCore
@_spi(STP) import StripeFinancialConnections

enum SetCollectMobileFinancialConnectionsResult {
    struct Value: Codable, Equatable {
        struct FinancialConnectionsSession: Codable, Equatable {
            let accounts: [StripeAPI.FinancialConnectionsAccount]
        }

        let financialConnectionsSession: FinancialConnectionsSession
        let token: StripeAPI.BankAccountToken
    }

    static func sender(value: Value?) -> CallSetterWithSerializableValueSender<Value?> {
        .init(payload: .init(setter: "setCollectMobileFinancialConnectionsResult",
                             value: value))
    }
}

enum FinancialConnectionsError {

}
