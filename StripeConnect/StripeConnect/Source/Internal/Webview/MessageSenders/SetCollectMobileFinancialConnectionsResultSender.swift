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
        /// containing minimal properties needed by Stripe.js
        struct FinancialConnectionsSession: Codable, Equatable {
            let accounts: [StripeAPI.FinancialConnectionsAccount]
        }

        /// Unique identifier (UUID) returned to the web view with the FinancialConnections
        /// result in `setCollectMobileFinancialConnectionsResult` message
        let id: String
        /// Contains list of accounts
        let financialConnectionsSession: FinancialConnectionsSession?
        /// Bank account token, if there is one
        let token: StripeAPI.BankAccountToken?

        // Use explicit CodingKeys instead of synthesizing so we can reference
        // them in `keyEncodingStrategy(forKeys:)`
        enum CodingKeys: CodingKey {
            case id
            case financialConnectionsSession
            case token
        }
    }

    static func sender(value: PayloadValue) -> CallSetterWithSerializableValueSender<PayloadValue?> {
        .init(payload: .init(setter: "setCollectMobileFinancialConnectionsResult",
                             value: value),
              customKeyEncodingStrategy: keyEncodingStrategy)
    }

    static func keyEncodingStrategy(forKeys keys: [any CodingKey]) -> any CodingKey {
        /*
         The `financialConnectionsSession` and `token` properties should encode
         to Stripe.js types, which use snake_case.
         Top-level payload properties should retain their camelCase encoding.
         */
        let lastKey = keys.last!

        // Determine if the key is for a sub-property of
        // `financialConnectionsSession` or `token`
        guard !(lastKey is PayloadValue.CodingKeys),
            keys.contains(where: { $0 is PayloadValue.CodingKeys }) else {
            return lastKey
        }

        return StringCodingKey(
            URLEncoder.convertToSnakeCase(camelCase: lastKey.stringValue)
        )
    }
}

extension FinancialConnectionsSheet.TokenResult {
    /// Converts the result into one that can be sent to Stripe.js.
    /// If an error was returned by FinancialConnections, it will be logged to analytics.
    func toSenderValue(id: String, analyticsClient: ComponentAnalyticsClient) -> SetCollectMobileFinancialConnectionsResult.PayloadValue {
        switch self {
        case .completed(result: (let session, let token)):
            return .init(
                id: id,
                financialConnectionsSession: .init(accounts: session.accounts.data),
                token: token
            )

        case .failed(error: let error):
            analyticsClient.logClientError(error)
            return .init(
                id: id,
                financialConnectionsSession: nil,
                token: nil
            )

        case .canceled:
            return .init(
                id: id,
                financialConnectionsSession: .init(accounts: []),
                token: nil
            )
        }
    }
}
