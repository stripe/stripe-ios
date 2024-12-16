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

        /// Contains list of accounts
        let financialConnectionsSession: FinancialConnectionsSession?
        /// Bank account token, if there is one
        let token: StripeAPI.BankAccountToken?
        /// Stripe API error if an error occurred of this error type
        let error: StripeAPIError?

        // Use explicit CodingKeys instead of synthesizing so we can reference
        // them in `keyEncodingStrategy(forKeys:)`
        enum CodingKeys: CodingKey {
            case financialConnectionsSession
            case token
            case error
        }
    }

    /// Sends the result returned from the FinancialConnectionsSheet back to the web view
    static func sender(value: PayloadValue) -> CallSetterWithSerializableValueSender<PayloadValue> {
        .init(payload: .init(setter: "setCollectMobileFinancialConnectionsResult",
                             value: value),
              customKeyEncodingStrategy: keyEncodingStrategy)
    }

    /// Custom key encoding strategy for `PayloadValue`
    private static func keyEncodingStrategy(forKeys keys: [any CodingKey]) -> any CodingKey {
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
    func toSenderValue(analyticsClient: ComponentAnalyticsClient) -> SetCollectMobileFinancialConnectionsResult.PayloadValue {
        switch self {
        case .completed(result: (let session, let token)):
            return .init(
                financialConnectionsSession: .init(accounts: session.accounts.data),
                token: token,
                error: nil
            )

        case .failed(error: StripeError.apiError((let apiError))):
            // API Error
            return .init(
                financialConnectionsSession: nil,
                token: nil,
                error: apiError
            )

        case .failed(error: let error):
            // Client error
            analyticsClient.logClientError(error)
            return .init(
                financialConnectionsSession: nil,
                token: nil,
                error: nil
            )

        case .canceled:
            return .init(
                financialConnectionsSession: .init(accounts: []),
                token: nil,
                error: nil
            )
        }
    }
}
