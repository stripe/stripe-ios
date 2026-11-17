//
//  SheetClosedSender.swift
//  StripeConnect
//

import Foundation

/// Tells Connect.js that a native sheet an inline component opened went away, for any reason
struct SheetClosedSender: MessageSender {
    struct Payload: Codable, Equatable {
        let sheetId: String
    }
    let name: String = "sheetClosed"
    let payload: Payload
}
