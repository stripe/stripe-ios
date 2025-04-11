//
//  FetchAppInfoMessageHandler.swift
//  StripeConnect
//
//  Created by Chris Mays on 4/10/25.
//

import Foundation

// This message is emitted when connect embed requests info about the app.
@available(iOS 15, *)
class FetchAppInfoMessageHandler: ScriptMessageHandlerWithReply<VoidPayload, FetchAppInfoMessageHandler.Reply> {
    struct Reply: Encodable {
        let applicationId: String
    }
    init(didReceiveMessage: @escaping (VoidPayload) async throws -> Reply) {
        super.init(name: "fetchAppInfo", didReceiveMessage: didReceiveMessage)
    }
}
