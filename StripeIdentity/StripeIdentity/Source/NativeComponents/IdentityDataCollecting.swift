//
//  IdentityDataCollecting.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/26/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

protocol IdentityDataCollecting {
    /// Which fields this view controller has collected from the user
    var collectedFields: Set<StripeAPI.VerificationPageFieldType> { get }

    /// Resets the state of the view controller
    func reset()
}

extension IdentityDataCollecting {
    func reset() {
        // Default implementation
    }
}

extension IdentityDataCollecting where Self: IdentityFlowViewController {
    func clearCollectedFields() {
        collectedFields.forEach { self.sheetController?.collectedData.clearData(field: $0) }
    }

    func reset() {
        clearCollectedFields()
    }
}
