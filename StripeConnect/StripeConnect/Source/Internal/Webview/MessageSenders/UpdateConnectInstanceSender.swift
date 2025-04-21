//
//  UpdateConnectInstanceSender.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/2/24.
//

import Foundation

/// Updates appearance and locale options.
@available(iOS 15, *)
struct UpdateConnectInstanceSender: MessageSender {
    struct Payload: Encodable {
        let locale: String
        private(set) var appearance: AppearanceWrapper
    }
    let name: String = "updateConnectInstance"
    let payload: Payload
}
