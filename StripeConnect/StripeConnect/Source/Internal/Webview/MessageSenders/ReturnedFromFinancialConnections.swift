//
//  ReturnedFromFinancialConnections.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/17/24.
//

/// Notifies that the user finished the FinancialConnections flow
struct ReturnedFromFinancialConnections: MessageSender {
    struct Payload: Codable, Equatable {
        /// The linked bank account token.
        /// This value will be nil if the user canceled the flow or an error occurred.
        let bankToken: String?
        /// Unique identifier that is included in the `openFinancialConnections` message
        let id: String
    }
    let name: String = "returnedFromFinancialConnections"
    let payload: Payload
}
