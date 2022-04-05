//
//  IdentityDataCollecting.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/26/22.
//

import Foundation
import UIKit

protocol IdentityDataCollecting {
    /// Which fields this view controller has collected from the user
    var collectedFields: Set<VerificationPageFieldType> { get }

    /// Resets the state of the view controller
    func reset()
}

extension IdentityDataCollecting {
    func reset() {
        // Default implementation
    }
}
