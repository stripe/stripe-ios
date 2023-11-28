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
                "Front of identity card",
                "Title of ID document scanning screen when scanning the front of an identity card"
            )
        } else {
            return STPLocalizedString(
                "Back of identity card",
                "Title of ID document scanning screen when scanning the back of an identity card"
            )
        }
    }

    func scanningInstructionText(
        for side: DocumentSide,
        foundClassification: IDDetectorOutput.Classification?
    ) -> String {
        let matchesClassification =
        foundClassification?.matchesDocument(side: side) ?? false
        switch (side, matchesClassification) {
        case (.front, false):
            return STPLocalizedString(
                "Position your identity card in the center of the frame",
                "Instructional text for scanning front of a identity card"
            )
        case (.back, false):
            return STPLocalizedString(
                "Flip your identity card over to the other side",
                "Instructional text for scanning back of a identity card"
            )
        case (_, true):
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
