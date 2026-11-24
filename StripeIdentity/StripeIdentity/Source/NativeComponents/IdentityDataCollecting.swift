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
        collectedFields.forEach { self.sheetController?.clearCollectedData(field: $0) }
    }

    func reset() {
        clearCollectedFields()
    }
}

/// A capture screen that can save its capture again after an image upload failed.
protocol RetriesSaveAfterError: UIViewController {
    /// Whether uploading the failed images of the current capture again can succeed. Preparing an
    /// image (`STPCGImageError`) fails the same way every time, so only a failed request can.
    var canRetryFailedUploads: Bool { get }

    /// Uploads again only the images that failed, then saves the capture again. Call it after the
    /// capture screen appears again: `DocumentCaptureViewController.viewWillAppear` reads a running
    /// save as a force-confirmed front.
    func retrySaveAfterError()
}
