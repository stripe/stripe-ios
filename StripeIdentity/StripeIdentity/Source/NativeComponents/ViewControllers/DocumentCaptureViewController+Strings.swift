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
        let localizedTypes = availableIDTypes.compactMap { $0.uiIDType() }

        func fallback() -> String {
            switch side {
            case .front:
                return String.Localized.position_in_center_identity_card
            case .back:
                return String.Localized.flip_to_other_side_identity_card
            }

        }

        // Handle specific combinations for scanning instructions
        if localizedTypes.count == 2 {
            if localizedTypes.contains(String.Localized.driverLicense) && localizedTypes.contains(String.Localized.passport) {
                return side == .front ? String.Localized.positionDriverLicenseOrPassport : String(format: String.Localized.flip_to_other_side, String.Localized.driverLicense)
            } else if localizedTypes.contains(String.Localized.driverLicense) && localizedTypes.contains(String.Localized.governmentIssuedId) {
                return side == .front ? String.Localized.positionDriverLicenseOrGovernmentId : String.Localized.flipDriverLicenseOrGovernmentId
            } else if localizedTypes.contains(String.Localized.passport) && localizedTypes.contains(String.Localized.governmentIssuedId) {
                return side == .front ? String.Localized.positionPassportOrGovernmentId : String(format: String.Localized.flip_to_other_side, String.Localized.governmentIssuedId)
            } else {
                return fallback()
            }
        } else if localizedTypes.count == 3 {
            // Handle all three types for scanning instructions
            return side == .front ? String.Localized.positionAllIdTypes : String.Localized.flipDriverLicenseOrGovernmentId
        } else if localizedTypes.count == 1, let type = localizedTypes.first {
            // Handle single type
            switch side {
            case .front:
                return String(format: String.Localized.position_in_center, type)
            case .back:
                return String(format: String.Localized.flip_to_other_side, type)
            }
        } else {
            // Fallback to generic text
            return fallback()
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
        case .some(.legacy(let idDetectorOutput, _, let motionblur, _, _)):
            let foundClassification = idDetectorOutput.classification
            let matchesClassification = foundClassification.matchesDocument(side: side)
            let zoomLevel = idDetectorOutput.computeZoomLevel()

            if foundClassification == .invalid {
                return String.Localized.invalid_document
            }
            
            // If document appears off-center, ask user to center it (only when the side matches)
            if matchesClassification {
                let cx = Double(idDetectorOutput.documentBounds.midX)
                let cy = Double(idDetectorOutput.documentBounds.midY)
                if abs(cx - 0.5) > 0.08 || abs(cy - 0.5) > 0.08 {
                    return String.Localized.center_id_in_view
                }
            }
            switch (side, matchesClassification, zoomLevel) {
            case (.front, false, _), (.back, false, _):
                switch (side, foundClassification) {
                case (.front, .idCardBack):
                    return String.Localized.front_of_id_not_detected
                case (.back, .idCardFront), (.back, .passport):
                    return String.Localized.back_of_id_not_detected
                default:
                    return scanningTextWithNoInput(availableIDTypes: availableIDTypes, for: side)
                }
            case (_, true, .ok):
                if motionblur.hasMotionBlur {
                    return String.Localized.reduce_blur
                }
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
