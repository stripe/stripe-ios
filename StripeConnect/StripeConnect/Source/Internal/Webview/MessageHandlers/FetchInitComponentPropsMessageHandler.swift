//
//  FetchInitComponentPropsMessageHandler.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 9/27/24.
//

import Foundation

// Fetches initial property values specific to this component.
@available(iOS 15, *)
class FetchInitComponentPropsMessageHandler: ScriptMessageHandlerWithReply<VoidPayload, ComponentType> {
    init(componentType: ComponentType) {
        super.init(name: "fetchInitComponentProps") { _ in
            componentType
        }
    }
}
