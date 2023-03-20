//
//  CancellationReason.swift
//  StripeCardScan
//
//  Created by Jaime Park on 11/17/21.
//

import Foundation

/// The reason of the user initiated scan cancellation
public enum CancellationReason: String, Equatable {
    /// User pressed the back button
    case back
    /// User closed the sheet view
    case closed
    /// User pressed the button which indicates that they can not scan the expected card
    case userCannotScan
}
