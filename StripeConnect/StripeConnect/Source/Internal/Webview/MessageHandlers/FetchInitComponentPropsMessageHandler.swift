//
//  FetchInitComponentPropsMessageHandler.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 9/27/24.
//

import Foundation

// Fetches initial property values specific to this component.
@available(iOS 15, *)
class FetchInitComponentPropsMessageHandler<Props: Encodable>: ScriptMessageHandlerWithReply<VoidPayload, Props> {
    init(_ fetchInitProps: @escaping () async throws -> Props) {
        super.init(name: "fetchInitComponentProps") { _ in
            try await fetchInitProps()
        }
    }
}
