//
//  HTMLConfirmationResult.swift
//  StripePaymentSheet
//
//  Created by Michael Liberatore on 8/27/26.
//

import Foundation

/// An action taken from an HTML confirmation screen.
enum HTMLConfirmationResult {

    /// The customer confirmed the displayed content.
    case confirmed

    /// The customer dismissed the screen without confirming.
    case canceled
}
