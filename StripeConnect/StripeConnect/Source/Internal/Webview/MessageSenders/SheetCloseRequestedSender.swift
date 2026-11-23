//
//  SheetCloseRequestedSender.swift
//  StripeConnect
//

import Foundation

/// Tells Connect.js that the user tried to close a native sheet that isn't dismissible, so its dialog can decide
struct SheetCloseRequestedSender: MessageSender {
    struct Payload: Codable, Equatable {
        let sheetId: String
    }
    let name: String = "sheetCloseRequested"
    let payload: Payload
}
