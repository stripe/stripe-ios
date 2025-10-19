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
    init(_ fetchInitProps: @escaping () async throws -> Props,
        registerSupplementalFunctions: @escaping (SupplementalFunctions) -> Void
    ) {
        super.init(name: "fetchInitComponentProps") { _ in
            let props = try await fetchInitProps()
            // We can avoid the type cast in the future by making Props conform to a protocol
            // which allows for optional SupplementalFunctions, once this approach is proved out
            if let fnProps = props as? any HasSupplementalFunctions {
                registerSupplementalFunctions(fnProps.supplementalFunctions)
            }
            return props
        }
    }
}
