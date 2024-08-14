//
//  FetchInitParamsMessageHandler.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/7/24.
//

import Foundation

// This message is emitted when the SDK is requesting initialization info.
class FetchInitParamsMessageHandler: ScriptMessageHandlerWithReply<VoidPayload, FetchInitParamsMessageHandler.Reply> {
    struct Reply: Codable, Equatable {
        let locale: String
        // TODO: Add fonts & appearance here.
    }
    init(didReceiveMessage: @escaping (VoidPayload) async throws -> Reply) {
        super.init(name: "fetchInitParams", didReceiveMessage: didReceiveMessage)
    }
}
