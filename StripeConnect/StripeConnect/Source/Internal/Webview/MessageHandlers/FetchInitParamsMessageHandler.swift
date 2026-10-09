//
//  FetchInitParamsMessageHandler.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/7/24.
//

import Foundation
@_spi(STP) import StripeCore

// This message is emitted when the SDK is requesting initialization info.
class FetchInitParamsMessageHandler: ScriptMessageHandlerWithReply<VoidPayload, FetchInitParamsMessageHandler.Reply> {
    struct Reply: Encodable {
        let locale: String
        var appearance: AppearanceWrapper
        var fonts: [CustomFontSourceWrapper] = []
    }
    init(sourcePolicy: STPWebMessageSourcePolicy,
         didReceiveMessage: @escaping (VoidPayload) async throws -> Reply) {
        super.init(name: "fetchInitParams", sourcePolicy: sourcePolicy, didReceiveMessage: didReceiveMessage)
    }
}
