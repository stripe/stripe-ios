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
        return STPLocalizedString("dc3808", "Status while screen is loading")
    }

    // MARK: - Additional Info fields

    static var date_of_birth: String {
        STPLocalizedString("fdc73",
            "Label for Date of birth field"
        )
    }

    static var date_of_birth_invalid: String {
        STPLocalizedString("2baa1",
            "Message for invalid Date of birth field"
        )
    }

    static var id_number_title: String {
        STPLocalizedString("a403d",
            "Label for ID number section"
        )
    }

    static var personal_id_number: String {
        STPLocalizedString("fae7d",
            "Label for the personal id number field in the hosted verification details collection form for countries without an exception"
        )
    }

    static var last_4_of_ssn: String {
        STPLocalizedString("77dd8",
            "Label for the ID field to collect last 4 of social security number for US ID"
        )
    }

    static var individual_cpf: String {
        STPLocalizedString("6212a",
            "Label for the ID field to collect individual CPF for Brazilian ID"
        )
    }

    static var nric_or_fin: String {
        STPLocalizedString("32e72",
            "Label for the ID field to collect NRIC or FIN for Singaporean ID"
        )
    }

    // MARK: - Document Capture

    static var position_in_center: String {
        return STPLocalizedString("ceab8",
            "Instructional text for scanning front of a driver's license, passport, or government issued photo id")
    }

    static var flip_to_other_side: String {
        return STPLocalizedString("e3292",
            "Instructional text for scanning back of a driver's license, passport, or government issued photo id"
        )
    }

    static var position_in_center_identity_card: String {
        return STPLocalizedString("68f51",
            "Instructional text for scanning front of a identity document")
    }

    static var flip_to_other_side_identity_card: String {
        return STPLocalizedString("87346",
            "Instructional text for scanning back of a identity card"
        )
    }

    static var scanning: String {
        return STPLocalizedString("b63f6",
            "Instructional text when camera is focusing on a document while scanning it"
        )
    }

    static var move_closer: String {
        return STPLocalizedString("1da05",
            "Instructional text when camera is too far from a document"
        )
    }

    static var move_farther: String {
        return STPLocalizedString("73333",
            "Instructional text when camera is too close to a document"
        )
    }

    static var rotate_document: String {
        return STPLocalizedString("6be11",
            "Instructional text when user needs to rorate to document to align with camera"
        )
    }

    static var keep_fully_visibile: String {
        return STPLocalizedString("687cd",
            "Instructional text when user needs remove anything blocking the document"
        )
    }

    static var align_document: String {
        return STPLocalizedString("6be11",
            "Instructional text when user align the edge with camera"
        )
    }

    static var increase_lighting: String {
        return STPLocalizedString("f579f",
            "Instructional text when environement is too dark"
        )
    }

    static var decrease_lighting: String {
        return STPLocalizedString("687cd",
            "Instructional text when environement is too bright"
        )
    }

    static var decrease_lighting_2: String {
        return STPLocalizedString("4687a",
            "Instructional text when environement is too bright"
        )
    }

    static var reduce_glare: String {
        return STPLocalizedString("687cd",
            "Instructional text when the document is too glarry"
        )
    }

    static var reduce_glare_2: String {
        return STPLocalizedString("ffd3d",
            "Instructional text when the document is too glarry"
        )
    }

    static var reduce_blur: String {
        return STPLocalizedString("859af",
            "Instructional text when the document is too blurry"
        )
    }

    static var point_camera_to_document: String {
        return STPLocalizedString("b376f",
            "Instructional text when there is no document in camera frame"
        )
    }

    // MARK: - Document Upload

    static var app_settings: String {
        STPLocalizedString("da645",
            "Opens the app's settings in the Settings app"
        )
    }

    static var select: String {
        STPLocalizedString("2a780",
            "Button to select a file to upload"
        )
    }

    static var upload_your_photo_id: String {
        STPLocalizedString("40a76",
            "Title of document upload screen"
        )
    }

    // MARK: - Camera Capturing

    static var upload_a_photo: String {
        STPLocalizedString("f0c8a",
            "Button that opens file upload screen"
        )
    }

    static var try_again_button: String {
        STPLocalizedString("df0fe",
            "Button to attempt to re-scan identity document image"
        )
    }

    static var noCameraAccessErrorTitleText: String {
        STPLocalizedString("51e72",
            "Error title displayed to the user when camera permissions have been denied"
        )
    }

    static var noCameraAccessErrorBodyText: String {
        STPLocalizedString("a98b4",
            "Line 1 of error text displayed to the user when camera permissions have been denied"
        )
    }

    static var timeoutErrorTitleText: String {
        STPLocalizedString("bf6e9",
            "Error title displayed to the user if we could not scan a high quality image of the user's identity document in a reasonable amount of time"
        )
    }

    static var timeoutErrorBodyText: String {
        STPLocalizedString("55e29",
            "Error text displayed to the user if we could not scan a high quality image of the user's identity document in a reasonable amount of time"
        )
    }

    static var unsavedChanges: String {
        STPLocalizedString("a710c",
            "Title for warning alert"
        )
    }

    static var cameraUnavailableErrorTitleText: String {
        STPLocalizedString("06cc3",
            "Error title displayed to the user when the device's camera is not available"
        )
    }

    static var cameraUnavailableErrorBodyText: String {
        STPLocalizedString("1eda8",
            "Error text displayed to the user when the device's camera is not available"
        )
    }

    // MARK: - Phone
    static var phoneNumber: String {
        STPLocalizedString("72dba",
            "Section title for collection phone number"
        )
    }

    // MARK: - Selfie
    static var selfieWarmupTitle: String {
        STPLocalizedString("9e29f",
            "Title for selfie warmup page"
        )
    }

    static var selfieWarmupBody: String {
        STPLocalizedString("40b57",
            "Body for selfie warmup page"
        )
    }

    // MARK: - DocumentFileUpload
    static var fileUploadInstructionText: String {
        STPLocalizedString("8c273",
            "Instructions for uploading images of identity document"
        )
    }

    static var fileUploadInstructionTextSpecific: String {
        STPLocalizedString("03fa9",
            "Instructions for uploading images of a driver's license, government issued photo id, or passport"
        )
    }

    static var uploadYourSpecificDocument: String {
        STPLocalizedString("7f6c1",
            "Title of document upload screen"
        )
    }

    // MARK: - Document Selection Accessibility Labels
    static var selectFrontSpecificDocumentPhoto: String {
        STPLocalizedString("1ca11",
            "Accessibility label to select a photo of front of driver's license, passport, or government issued photo id"
        )
    }

    static var selectBackSpecificDocumentPhoto: String {
        STPLocalizedString("0dfa8",
            "Accessibility label to select a photo of back of driver's license, passport, or government issued photo id"
        )
    }

    static var selectFrontIdentityDocumentPhoto: String {
        STPLocalizedString("5c25a",
            "Accessibility label to select a photo of front of identity document"
        )
    }

    static var selectBackIdentityDocumentPhoto: String {
        STPLocalizedString("38aec",
            "Accessibility label to select a photo of back of identity document"
        )
    }

    // MARK: - Document Upload Accessibility Labels
    static var uploadingFrontSpecificDocumentPhoto: String {
        STPLocalizedString("93af2",
            "Accessibility label while photo of front of driver's license, passport, or government issued photo id is uploading"
        )
    }

    static var uploadingBackSpecificDocumentPhoto: String {
        STPLocalizedString("eaebd",
            "Accessibility label while photo of back of driver's license, passport, or government issued photo id is uploading"
        )
    }

    static var uploadingFrontIdentityDocumentPhoto: String {
        STPLocalizedString("5dfbf",
            "Accessibility label while photo of front of identity document is uploading"
        )
    }

    static var uploadingBackIdentityDocumentPhoto: String {
        STPLocalizedString("e16b7",
            "Accessibility label while photo of back of identity document is uploading"
        )
    }

    // MARK: - Document Upload Success Accessibility Labels
    static var frontSpecificDocumentPhotoUploadedSuccessfully: String {
        STPLocalizedString("b57ad",
            "Accessibility label when front driver's license, passport, or government issued photo id photo has successfully uploaded"
        )
    }

    static var backSpecificDocumentPhotoUploadedSuccessfully: String {
        STPLocalizedString("31438",
            "Accessibility label when back driver's license, passport, or government issued photo id photo has successfully uploaded"
        )
    }

    static var frontIdentityDocumentPhotoUploadedSuccessfully: String {
        STPLocalizedString("3a9fd",
            "Accessibility label when front identity document photo has successfully uploaded"
        )
    }

    static var backIdentityDocumentPhotoUploadedSuccessfully: String {
        STPLocalizedString("3253a",
            "Accessibility label when back identity document photo has successfully uploaded"
        )
    }

    // MARK: - Document Side Titles 
    static var frontOfSpecificDocument: String {
        STPLocalizedString("73fc5",
            "Title of ID document scanning screen when scanning the front of either a driver's license, passport, or government issued photo id "
        )
    }

    static var backOfSpecificDocument: String {
        STPLocalizedString("128b0",
            "Title of ID document scanning screen when scanning the back of either a driver's license, passport, or government issued photo id"
        )
    }

    // MARK: - DocumentWarmup
    static var documentFrontWarmupTitle: String {
        STPLocalizedString("83016",
            "Title for document front warmup page"
        )
    }

    static var documentFrontWarmupBody: String {
        STPLocalizedString("6c2aa",
            "Body for selfie warmup page"
        )
    }

    static var acceptFormsOfId: String {
        STPLocalizedString("a9934",
            "Title for accepted types of ids"
        )
    }

    static var imReady: String {
        STPLocalizedString("d5b05",
            "Ready button text on warmup screen"
        )
    }

    static var passport: String {
        STPLocalizedString("cbc47",
            "passport"
        )
    }

    static var governmentIssuedId: String {
        STPLocalizedString("29fd8",
            "id issued by government"
        )
    }

    static var driverLicense: String {
        STPLocalizedString("cadf1",
            "driver's license"
        )
    }

    // MARK: - Document Type Combinations for DocumentSide titles
    static var frontOfDriverLicenseOrPassport: String {
        STPLocalizedString("8d188",
            "Front of driver's license or passport"
        )
    }

    static var frontOfDriverLicenseOrGovernmentId: String {
        STPLocalizedString("b3d9a",
            "Front of driver's license or government-issued photo ID"
        )
    }

    static var backOfDriverLicenseOrGovernmentId: String {
        STPLocalizedString("37929",
            "Back of driver's license or government-issued photo ID"
        )
    }

    static var frontOfPassportOrGovernmentId: String {
        STPLocalizedString("bb2ee",
            "Front of passport or government-issued photo ID"
        )
    }

    static var frontOfAllIdTypes: String {
        STPLocalizedString("070b5",
            "Front of driver's license, passport, or government-issued photo ID"
        )
    }

    // MARK: - Document Type Combinations for scanning instructions
    static var positionDriverLicenseOrPassport: String {
        STPLocalizedString("453ad",
            "Position your driver's license or passport in the center of the frame"
        )
    }

    static var positionDriverLicenseOrGovernmentId: String {
        STPLocalizedString("12559",
            "Position your driver's license or government-issued photo ID in the center of the frame"
        )
    }

    static var flipDriverLicenseOrGovernmentId: String {
        STPLocalizedString("dd41b",
            "Flip your driver's license or government-issued photo ID over to the other side"
        )
    }

    static var positionPassportOrGovernmentId: String {
        STPLocalizedString("74830",
            "Position your passport or government-issued photo ID in the center of the frame"
        )
    }

    static var positionAllIdTypes: String {
        STPLocalizedString("ad934",
            "Position your driver's license, passport, or government-issued photo ID in the center of the frame"
        )
    }

}
