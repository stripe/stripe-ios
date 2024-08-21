//
//  UpdateConnectInstanceSender.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/2/24.
//

import Foundation

/// Updates appearance and locale options.
struct UpdateConnectInstanceSender: MessageSender {
    struct Payload: Codable, Equatable {
        let locale: String
        // TODO: Add appearance here.
    }
    let name: String = "updateConnectInstance"
    let payload: Payload
}
