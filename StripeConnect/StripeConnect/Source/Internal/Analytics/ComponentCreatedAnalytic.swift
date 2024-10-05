//
//  ComponentCreatedAnalytic.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/4/24.
//

struct ComponentCreatedAnalytic: ConnectAnalyticEvent {
    struct Metadata: Encodable { }

    let eventName = "component.created"
    let eventMetadata = Metadata()
}
