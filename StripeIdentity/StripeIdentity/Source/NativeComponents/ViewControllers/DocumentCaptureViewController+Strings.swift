//
//  DocumentCaptureViewController+Strings.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/7/22.
//

import Foundation

@available(iOSApplicationExtension, unavailable)
extension DocumentCaptureViewController {

    func titleText(for side: DocumentSide) -> String {
        switch (documentType, side) {
        case (.drivingLicense, .front):
            return STPLocalizedString(
                "Front of driver's license",
                "Title of ID document scanning screen when scanning the front of a driver's license"
            )
        case (.drivingLicense, .back):
            return STPLocalizedString(
                "Back of driver's license",
                "Title of ID document scanning screen when scanning the back of a driver's license"
            )
        case (.idCard, .front):
            return STPLocalizedString(
                "Front of identity card",
                "Title of ID document scanning screen when scanning the front of an identity card"
            )
        case (.idCard, .back):
            return STPLocalizedString(
                "Back of identity card",
                "Title of ID document scanning screen when scanning the back of an identity card"
            )
        case (.passport, _):
            return STPLocalizedString(
                "Passport",
                "Title of ID document scanning screen when scanning a passport"
            )
        }
    }

    func scanningInstructionText(
        for side: DocumentSide,
        foundClassification: IDDetectorOutput.Classification?
    ) -> String {
        let matchesClassification = foundClassification?.matchesDocument(type: documentType, side: side) ?? false

        switch (documentType, side, matchesClassification) {
        case (.drivingLicense, .front, false):
            return STPLocalizedString(
                "Position your driver's license in the center of the frame",
                "Instructional text for scanning front of a driver's license"
            )
        case (.drivingLicense, .back, false):
            return STPLocalizedString(
                "Flip your driver's license over to the other side",
                "Instructional text for scanning back of a driver's license"
            )
        case (.idCard, .front, false):
            return STPLocalizedString(
                "Position your identity card in the center of the frame",
                "Instructional text for scanning front of a identity card"
            )
        case (.idCard, .back, false):
            return STPLocalizedString(
                "Flip your identity card over to the other side",
                "Instructional text for scanning back of a identity card"
            )
        case (.passport, _, false):
            return STPLocalizedString(
                "Position your passport in the center of the frame",
                "Instructional text for scanning a passport"
            )
        case (_, _, true):
            return STPLocalizedString(
                "Hold still, scanning",
                "Instructional text when camera is focusing on a document while scanning it"
            )
        }
    }

    static var scannedInstructionalText: String {
        STPLocalizedString(
            "Scanned",
            "State when identity document has been successfully scanned"
        )
    }

    static var noCameraAccessErrorTitleText: String {
        STPLocalizedString(
            "Camera permission",
            "Error title displayed to the user when camera permissions have been denied"
        )
    }

    var noCameraAccessErrorBodyText: String {
        let line1 = STPLocalizedString(
            "We need permission to use your camera. Please allow camera access in app settings.",
            "Line 1 of error text displayed to the user when camera permissions have been denied"
        )
        if apiConfig.requireLiveCapture {
            return line1
        }

        let line2 = STPLocalizedString(
            "Alternatively, you may manually upload a photo of your identity document.",
            "Line 2 of error text displayed to the user when camera permissions have been denied and manually uploading a file is allowed"
        )

        return "\(line1)\n\n\(line2)"
    }

    static var cameraUnavailableErrorTitleText: String {
        STPLocalizedString(
            "Camera unavailable",
            "Error title displayed to the user when the device's camera is not available"
        )
    }

    static var cameraUnavailableErrorBodyText: String {
        STPLocalizedString(
            "There was an error accessing the camera.",
            "Error text displayed to the user when the device's camera is not available"
        )
    }

    static var timeoutErrorTitleText: String {
        STPLocalizedString(
            "Could not capture image",
            "Error title displayed to the user if we could not scan a high quality image of the user's identity document in a reasonable amount of time"
        )
    }

    var timeoutErrorBodyText: String {
        let line1 = STPLocalizedString(
            "We could not capture a high-quality image.",
            "Line 1 of error text displayed to the user if we could not scan a high quality image of the user's identity document in a reasonable amount of time and manually uploading a file is allowed"
        )
        let line2 = STPLocalizedString(
            "You can either try again or upload an image from your device.",
            "Line 2 of error text displayed to the user if we could not scan a high quality image of the user's identity document in a reasonable amount of time and manually uploading a file is allowed"
        )

        return "\(line1)\n\n\(line2)"
    }

    static var uploadButtonText: String {
        STPLocalizedString(
            "Upload a Photo",
            "Button to upload a photo"
        )
    }
}
