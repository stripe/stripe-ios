//
//  OpenFinancialConnectionsMessageHandler.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/17/24.
//

@_spi(STP) import StripeCore

/// Indicates to open the FinancialConnections flow
class OpenFinancialConnectionsMessageHandler: ScriptMessageHandler<OpenFinancialConnectionsMessageHandler.Payload> {
    struct Payload: Codable, Equatable {
        /// The Financial Connections Session client secret used to open the FinancialConnectionsSheet
        let clientSecret: String
        /// Unique identifier (UUID) to track the round-trip of the
        /// FinancialConnections flow returned to the web view with the
        /// result in `setCollectMobileFinancialConnectionsResult`
        let id: String
        /// The id of the Connected Account that requested the Financial Connections Session client secret
        let connectedAccountId: String
    }

    init(sourcePolicy: STPWebMessageSourcePolicy,
         analyticsClient: ComponentAnalyticsClient,
         didReceiveMessage: @escaping (Payload) -> Void) {
        super.init(name: "openFinancialConnections",
                   sourcePolicy: sourcePolicy,
                   analyticsClient: analyticsClient,
                   didReceiveMessage: didReceiveMessage)
    }
}
