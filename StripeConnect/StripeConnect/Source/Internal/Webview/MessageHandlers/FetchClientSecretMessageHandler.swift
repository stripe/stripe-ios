//
//  FetchClientSecretMessageHandler.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/2/24.
//

import Foundation

// Called when the client secret is needed for embedded components
class FetchClientSecretMessageHandler: ScriptMessageHandlerWithReply<VoidPayload, String?> {
    init(didReceiveMessage: @escaping (VoidPayload) async throws -> String?) {
        super.init(name: "fetchClientSecret", didReceiveMessage: didReceiveMessage)
    }
}
