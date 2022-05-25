//
//  SelfieCaptureViewController+Strings.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 4/27/22.
//

import Foundation

@available(iOSApplicationExtension, unavailable)
extension SelfieCaptureViewController {
    static var initialInstructionText: String {
        return STPLocalizedString(
            "Position your face in the center of the frame.",
            "Instructional text for scanning selfies"
        )
    }

    static var capturingInstructionText: String {
        return STPLocalizedString(
            "Capturing…",
            "Instructional text for scanning selfies"
        )
    }

    static var scannedInstructionText: String {
        return STPLocalizedString(
            "Selfie captures are complete",
            "Status text when selfie images have been captured"
        )
    }
}
