//
//  ComponentWebPageLoadedEvent.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/4/24.
//

import Foundation

/// The web page finished loading (`didFinish navigation` event).
struct ComponentWebPageLoadedEvent: ConnectAnalyticEvent {
    struct Metadata: Encodable, Equatable {
        /// Elapsed time in seconds it took the web page to load
        /// (starting when it first began loading).
        let timeToLoad: TimeInterval
    }

    let name = "component.web.page_loaded"
    let metadata: Metadata
}
