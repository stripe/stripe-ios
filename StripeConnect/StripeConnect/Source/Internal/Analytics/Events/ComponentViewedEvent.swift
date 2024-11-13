//
//  ComponentViewedEvent.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/4/24.
//

/// The component is viewed on screen (`viewDidAppear` lifecycle event)
struct ComponentViewedEvent: ConnectAnalyticEvent {
    struct Metadata: Encodable, Equatable { }

    let name = "component.viewed"
    let metadata = Metadata()
}
