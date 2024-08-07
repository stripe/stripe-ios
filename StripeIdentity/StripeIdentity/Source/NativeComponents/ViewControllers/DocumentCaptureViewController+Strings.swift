//
//  DocumentCaptureViewController+Strings.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/7/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension DocumentCaptureViewController {

    func titleText(for side: DocumentSide) -> String {
        if side == .front {
            return STPLocalizedString(
                "Front of identity document",
                "Title of ID document scanning screen when scanning the front of an identity card"
            )
        } else {
            return STPLocalizedString(
                "Back of identity document",
                "Title of ID document scanning screen when scanning the back of an identity card"
            )
        }
    }

    func scanningInstructionText(
        for side: DocumentSide,
        documentScannerOutput: DocumentScannerOutput?
    ) -> String {
        switch documentScannerOutput {
        case .none:
            if side == .front {
                return String.Localized.position_in_center
            } else {
                return String.Localized.flip_to_other_side
            }
        case .some(.legacy(let idDetectorOutput, _, _, _, _)):
            let foundClassification = idDetectorOutput.classification
            let matchesClassification = foundClassification.matchesDocument(side: side)
            let zoomLevel = idDetectorOutput.computeZoomLevel()
            switch (side, matchesClassification, zoomLevel) {
            case (.front, false, _):
                return String.Localized.position_in_center
            case (.back, false, _):
                return String.Localized.flip_to_other_side
            case (_, true, .ok):
                return String.Localized.scanning
            case (_, true, .tooClose):
                return String.Localized.move_farther
            case (_, true, .tooFar):
                return String.Localized.move_closer
            }
        }
    }

    static var scannedInstructionalText: String {
        STPLocalizedString(
            "Scanned",
            "State when identity document has been successfully scanned"
        )
    }

    var noCameraAccessErrorBodyText: String {
        if apiConfig.requireLiveCapture {
            return .Localized.noCameraAccessErrorBodyText
        }

        let line2 = STPLocalizedString(
            "Alternatively, you may manually upload a photo of your identity document.",
            "Line 2 of error text displayed to the user when camera permissions have been denied and manually uploading a file is allowed"
        )

        return "\(String.Localized.noCameraAccessErrorBodyText)\n\n\(line2)"
    }

    var timeoutErrorBodyText: String {
        if apiConfig.requireLiveCapture {
            return .Localized.timeoutErrorBodyText
        }

        let line2 = STPLocalizedString(
            "You can either try again or upload an image from your device.",
            "Line 2 of error text displayed to the user if we could not scan a high quality image of the user's identity document in a reasonable amount of time and manually uploading a file is allowed"
        )

        return "\(String.Localized.timeoutErrorBodyText)\n\n\(line2)"
    }

    static var uploadButtonText: String {
        STPLocalizedString(
            "Upload a Photo",
            "Button to upload a photo"
        )
    }
}
