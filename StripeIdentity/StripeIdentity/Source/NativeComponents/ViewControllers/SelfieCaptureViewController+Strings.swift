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
        return STPLocalizedString("6f758",
            "Instructional text for scanning selfies"
        )
    }

    static var capturingInstructionText: String {
        return STPLocalizedString("806e3",
            "Instructional text for scanning selfies"
        )
    }

    static var scannedInstructionText: String {
        return STPLocalizedString("a7b36",
            "Status text when selfie images have been captured"
        )
    }
}
