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

    func titleText(for side: DocumentSide, availableIDTypes: [String]) -> String {
        return side.instruction(availableIDTypes: availableIDTypes)
    }

    func scanningTextWithNoInput(availableIDTypes: [String], for side: DocumentSide) -> String {
        let type = (availableIDTypes.count == 1) ? availableIDTypes[0].uiIDType() : nil

        if let type = type {
            switch side {
            case .front:
                return String(format: String.Localized.position_in_center, type)
            case .back:
                return String(format: String.Localized.flip_to_other_side, type)
            }
        } else {
            switch side {
            case .front:
                return String.Localized.position_in_center_identity_card
            case .back:
                return String.Localized.flip_to_other_side_identity_card
            }
        }
    }

    func scanningInstructionText(
        for side: DocumentSide,
        documentScannerOutput: DocumentScannerOutput?,
        availableIDTypes: [String]
    ) -> String {
        switch documentScannerOutput {
        case .none:
            return scanningTextWithNoInput(availableIDTypes: availableIDTypes, for: side)
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
