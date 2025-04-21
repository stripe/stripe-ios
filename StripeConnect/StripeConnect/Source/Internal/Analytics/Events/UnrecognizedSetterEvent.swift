//
//  UnrecognizedSetterEvent.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/4/24.
//

import Foundation

/// If the web view calls `onSetterFunctionCalled` with a `setter` argument the SDK doesn’t know how to handle.
struct UnrecognizedSetterEvent: ConnectAnalyticEvent {
    struct Metadata: Encodable, Equatable {
        /// The `setter` property sent from web
        let setter: String

        /// The pageViewID from the web view
        /// - Note: May be null if not yet sent from web
        let pageViewId: String?
    }

    let name = "component.web.warn.unrecognized_setter_function"
    let metadata: Metadata
}
