//
//  ConnectAnalyticEvent.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/1/24.
//

protocol ConnectAnalyticEvent {
    associatedtype Metadata: Encodable

    var name: String { get }

    /// Event-specific metadata
    var metadata: Metadata { get }
}
