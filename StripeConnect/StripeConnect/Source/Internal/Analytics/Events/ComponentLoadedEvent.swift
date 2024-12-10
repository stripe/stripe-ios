//
//  ComponentLoadedEvent.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/4/24.
//

import Foundation

/// The component is successfully loaded within the web view.
/// Triggered from `componentDidLoad` message handler from the web view.
struct ComponentLoadedEvent: ConnectAnalyticEvent {
    struct Metadata: Encodable, Equatable {
        /// The pageViewID from the web view
        let pageViewId: String?

        /// Elapsed time in seconds it took the component to load
        /// (starting when the page first began loading).
        let timeToLoad: TimeInterval

        /// Elapsed time in seconds in took between when the component was
        /// initially viewed on screen (`component.viewed`) to when the component
        /// finished loading. This value will be `0` if the component finished
        /// loading before being viewed on screen.
        let perceivedTimeToLoad: TimeInterval
    }

    let name = "component.web.component_loaded"
    let metadata: Metadata
}
