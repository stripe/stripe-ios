//
//  UnexpectedNavigationEvent.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 11/12/24.
//

import Foundation

/// The component web page navigated away from the component page to another URL
struct UnexpectedNavigationEvent: ConnectAnalyticEvent {
    struct Metadata: Codable, Equatable {
        let url: String?

        init(url: URL?) {
            // Sanitize URL for logging
            self.url = url?
                .absoluteStringRemovingParams
        }
    }

    let name = "component.web.error.unexpected_navigation"
    let metadata: Metadata
}
