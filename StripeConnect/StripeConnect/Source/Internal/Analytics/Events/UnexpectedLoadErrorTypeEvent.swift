//
//  UnexpectedLoadErrorTypeEvent.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/4/24.
//

import Foundation

/// The web view sends an onLoadError that can’t be deserialized by the SDK.
struct UnexpectedLoadErrorTypeEvent: ConnectAnalyticEvent {
    struct Metadata: Encodable, Equatable {
        /// The error `type` property from web
        let errorType: String

        /// The pageViewID from the web view
        /// - Note: May be null if not yet sent from web
        let pageViewId: String?
    }

    let name = "component.web.warn.unexpected_load_error_type"
    let metadata: Metadata
}
