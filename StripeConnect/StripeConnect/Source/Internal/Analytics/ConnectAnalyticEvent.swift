//
//  ConnectAnalyticEvent.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/1/24.
//

import Foundation

/// Represents an analytics event logged from the Connect SDK
protocol ConnectAnalyticEvent: Equatable {
    associatedtype Metadata: Encodable & Equatable

    /// The `event_name` field of the event
    var name: String { get }

    /// Event-specific metadata, encoded as a JSON string in the `metadata` field
    var metadata: Metadata { get }
}
