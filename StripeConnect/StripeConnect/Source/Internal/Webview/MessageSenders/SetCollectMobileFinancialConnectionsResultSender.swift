//
//  SetCollectMobileFinancialConnectionsResultSender.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/17/24.
//
@_spi(STP) import StripeCore
@_spi(STP) import StripeFinancialConnections

enum SetCollectMobileFinancialConnectionsResult {
    struct PayloadValue: Codable, Equatable {
        /// Simplified version of `StripeAPI.FinancialConnectionsSession`
        /// containing minimal properties needed by StripeJS
        struct FinancialConnectionsSession: Codable, Equatable {
            let accounts: [StripeAPI.FinancialConnectionsAccount]
        }

        let financialConnectionsSession: FinancialConnectionsSession
        let token: StripeAPI.BankAccountToken?
    }

    static func sender(value: PayloadValue?) -> CallSetterWithSerializableValueSender<PayloadValue?> {
        .init(payload: .init(setter: "setCollectMobileFinancialConnectionsResult",
                             value: value))
    }
}

extension FinancialConnectionsSheet.TokenResult {
    /// Converts the result into one that can be sent to StripeJS.
    /// If an error was returned by FinancialConnections, it will be logged to analytics.
    func toSenderValue(analyticsClient: ComponentAnalyticsClient) -> SetCollectMobileFinancialConnectionsResult.PayloadValue? {
        switch self {
        case .completed(result: (let session, let token)):
            return .init(
                financialConnectionsSession: .init(accounts: session.accounts.data),
                token: token
            )

        case .failed(error: let error):
            analyticsClient.logClientError(error)
            return nil

        case .canceled:
            return .init(
                financialConnectionsSession: .init(accounts: []),
                token: nil
            )
        }
    }
}
