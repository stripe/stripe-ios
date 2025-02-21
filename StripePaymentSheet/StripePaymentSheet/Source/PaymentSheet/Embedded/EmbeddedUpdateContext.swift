//
//  EmbeddedUpdateContext.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/14/25.
//

import Foundation

struct EmbeddedUpdateContext {
    /// The ID of the update API call
    let id: UUID = UUID()

    /// Tracks where we are in the update lifecycle
    var status: Status = .inProgress

    enum Status {
        /// Update in progress
        case inProgress
        /// The update successfully completed
        case succeeded
        // The update was canceled
        case canceled
        /// The update failed
        case failed(error: Error)
    }
}
