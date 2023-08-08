//
//  String+Localized.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 9/27/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

// Localized strings that are used in multiple contexts. Collected here to avoid re-translation
// We use snake case to make long names easier to read.
extension String.Localized {
    static var loading: String {
        return STPLocalizedString("Loading", "Status while screen is loading")
    }

    // MARK: - Additional Info fields

    static var date_of_birth: String {
        STPLocalizedString(
            "Date of Birth",
            "Label for Date of birth field"
        )
    }

    static var date_of_birth_invalid: String {
        STPLocalizedString(
            "Date of birth does not look valid",
            "Message for invalid Date of birth field"
        )
    }

    static var id_number_title: String {
        STPLocalizedString(
            "ID Number",
            "Label for ID number section"
        )
    }

    static var personal_id_number: String {
        STPLocalizedString(
            "Personal ID number",
            "Label for the personal id number field in the hosted verification details collection form for countries without an exception"
        )
    }

    static var last_4_of_ssn: String {
        STPLocalizedString(
            "Last 4 of Social Security number",
            "Label for the ID field to collect last 4 of social security number for US ID"
        )
    }

    static var individual_cpf: String {
        STPLocalizedString(
            "Individual CPF",
            "Label for the ID field to collect individual CPF for Brazilian ID"
        )
    }

    static var nric_or_fin: String {
        STPLocalizedString(
            "NRIC or FIN",
            "Label for the ID field to collect NRIC or FIN for Singaporean ID"
        )
    }

    // MARK: - Document Upload

    static var app_settings: String {
        STPLocalizedString(
            "App Settings",
            "Opens the app's settings in the Settings app"
        )
    }

    static var select: String {
        STPLocalizedString(
            "Select",
            "Button to select a file to upload"
        )
    }

    static var upload_your_photo_id: String {
        STPLocalizedString(
            "Upload your photo ID",
            "Title of document upload screen"
        )
    }

    // MARK: - Camera Capturing

    static var upload_a_photo: String {
        STPLocalizedString(
            "Upload a Photo",
            "Button that opens file upload screen"
        )
    }

    static var try_again_button: String {
        STPLocalizedString(
            "Try Again",
            "Button to attempt to re-scan identity document image"
        )
    }

    static var noCameraAccessErrorTitleText: String {
        STPLocalizedString(
            "Camera permission",
            "Error title displayed to the user when camera permissions have been denied"
        )
    }

    static var noCameraAccessErrorBodyText: String {
        STPLocalizedString(
            "We need permission to use your camera. Please allow camera access in app settings.",
            "Line 1 of error text displayed to the user when camera permissions have been denied"
        )
    }

    static var timeoutErrorTitleText: String {
        STPLocalizedString(
            "Could not capture image",
            "Error title displayed to the user if we could not scan a high quality image of the user's identity document in a reasonable amount of time"
        )
    }

    static var timeoutErrorBodyText: String {
        STPLocalizedString(
            "We could not capture a high-quality image.",
            "Error text displayed to the user if we could not scan a high quality image of the user's identity document in a reasonable amount of time"
        )
    }

    static var unsavedChanges: String {
        STPLocalizedString(
            "Unsaved changes",
            "Title for warning alert"
        )
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

    // MARK: - Phone
    static var phoneNumber: String {
        STPLocalizedString(
            "Phone Number",
            "Section title for collection phone number"
        )
    }

}
