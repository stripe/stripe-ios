//
//  ConnectAnalyticEvent.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/1/24.
//

protocol ConnectAnalyticEvent {
    associatedtype Metadata: Encodable

    var eventName: String { get }

    /// Event-specific metadata
    var eventMetadata: Metadata { get }
}
