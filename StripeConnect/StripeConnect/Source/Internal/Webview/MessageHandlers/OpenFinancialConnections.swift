//
//  OpenFinancialConnections.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/17/24.
//

/// Indicates to open the FinancialConnections flow
class OpenFinancialConnections: ScriptMessageHandler<OpenFinancialConnections.Payload> {
    struct Payload: Codable, Equatable {
        let clientSecret: String
        /// Unique identifier that is included in the `returnedFromFinancialConnections` message
        let id: String
    }
    init(didReceiveMessage: @escaping (Payload) -> Void) {
        super.init(name: "openFinancialConnections", didReceiveMessage: didReceiveMessage)
    }
}
