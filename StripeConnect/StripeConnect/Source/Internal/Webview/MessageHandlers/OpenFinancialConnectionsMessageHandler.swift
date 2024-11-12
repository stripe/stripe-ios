//
//  OpenFinancialConnectionsMessageHandler.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/17/24.
//

/// Indicates to open the FinancialConnections flow
class OpenFinancialConnectionsMessageHandler: ScriptMessageHandler<OpenFinancialConnectionsMessageHandler.Payload> {
    struct Payload: Codable, Equatable {
        /// The Financial Connections Session client secret used to open the FinancialConnectionsSheet
        let clientSecret: String
        /// Unique identifier (UUID) returned to the web view with the FinancialConnections
        /// result in `returnedFromFinancialConnections` message
        let id: String
    }
    init(didReceiveMessage: @escaping (Payload) -> Void) {
        super.init(name: "openFinancialConnections", didReceiveMessage: didReceiveMessage)
    }
}
