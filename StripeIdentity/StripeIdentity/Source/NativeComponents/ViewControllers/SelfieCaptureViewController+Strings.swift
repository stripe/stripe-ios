//
//  SelfieCaptureViewController+Strings.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 4/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

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

    static var lookLeftInstructionText: String {
        return STPLocalizedString(
            "Turn your head left.",
            "Instructional text for scanning the left side of a selfie"
        )
    }

    static var lookRightInstructionText: String {
        return STPLocalizedString(
            "Turn your head right.",
            "Instructional text for scanning the right side of a selfie"
        )
    }

    static var scannedInstructionText: String {
        return STPLocalizedString(
            "Selfie captures are complete",
            "Status text when selfie images have been captured"
        )
    }
}
