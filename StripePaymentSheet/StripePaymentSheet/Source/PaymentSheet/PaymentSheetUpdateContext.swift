//
//  PaymentSheetUpdateContext.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/24/23.
//

import Foundation

struct UpdateContext {
    /// The status of the last update API call
    var latestStatus: Status?
    /// The ID of the last update API call
    var latestID: UUID?

    enum Status {
        case completed
        case inProgress
        case failed
    }
}
