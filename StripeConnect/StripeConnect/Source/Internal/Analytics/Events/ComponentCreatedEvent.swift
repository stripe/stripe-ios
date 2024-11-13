//
//  ComponentCreatedEvent.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/4/24.
//

/// A component was instantiated via `create{ComponentType}`.
struct ComponentCreatedEvent: ConnectAnalyticEvent {
    struct Metadata: Encodable { }

    let name = "component.created"
    let metadata = Metadata()
}
