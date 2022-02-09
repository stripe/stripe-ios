//
//  DocumentFileUploadViewController+Strings.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/4/22.
//

import Foundation

@available(iOSApplicationExtension, unavailable)
extension DocumentFileUploadViewController {
    var instructionText: String {
        switch documentType {
        case .passport:
            return STPLocalizedString(
                "Please upload an image of your passport",
                "Instructions for uploading images of passport"
            )
        case .drivingLicense:
            return STPLocalizedString(
                "Please upload images of the front and back of your driver's license",
                "Instructions for uploading images of drivers license"
            )
        case .idCard:
            return STPLocalizedString(
                "Please upload images of the front and back of your identity card",
                "Instructions for uploading images of identity card"
            )
        }
    }

    func listItemText(for side: DocumentSide) -> String {
        switch (documentType, side) {
        case (.passport, _):
            return STPLocalizedString(
                "Image of passport",
                "Description of passport image"
            )
        case (.drivingLicense, .front):
            return STPLocalizedString(
                "Front of driver's license",
                "Description of front of driver's license image"
            )
        case (.drivingLicense, .back):
            return STPLocalizedString(
                "Back of driver's license",
                "Description of back of driver's license image"
            )
        case (.idCard, .front):
            return STPLocalizedString(
                "Front of identity card",
                "Description of front of identity card image"
            )
        case (.idCard, .back):
            return STPLocalizedString(
                "Back of identity card",
                "Description of back of identity card image"
            )
        }
    }

    func accessibilityLabel(for side: DocumentSide, uploadStatus: DocumentUploader.UploadStatus) -> String {
        switch uploadStatus {
        case .notStarted,
                .error:
            return selectAccessibilityLabel(for: side)
        case .inProgress:
            return uploadingAccessibilityLabel(for: side)
        case .complete:
            return uploadCompleteAccessibilityLabel(for: side)
        }
    }

    func selectAccessibilityLabel(for side: DocumentSide) -> String {
        switch (documentType, side) {
        case (.passport, _):
            return STPLocalizedString(
                "Select passport photo",
                "Accessibility label to select a photo of passport"
            )
        case (.drivingLicense, .front):
            return STPLocalizedString(
                "Select front driver's license photo",
                "Accessibility label to select a photo of front of driver's license"
            )
        case (.drivingLicense, .back):
            return STPLocalizedString(
                "Select back driver's license photo",
                "Accessibility label to select a photo of back of driver's license"
            )
        case (.idCard, .front):
            return STPLocalizedString(
                "Select front identity card photo",
                "Accessibility label to select a photo of front of identity card"
            )
        case (.idCard, .back):
            return STPLocalizedString(
                "Select back identity card photo",
                "Accessibility label to select a photo of back of identity card"
            )
        }
    }

    func uploadingAccessibilityLabel(for side: DocumentSide) -> String {
        switch (documentType, side) {
        case (.passport, _):
            return STPLocalizedString(
                "Uploading passport photo",
                "Accessibility label while photo of passport is uploading"
            )
        case (.drivingLicense, .front):
            return STPLocalizedString(
                "Uploading front driver's license photo",
                "Accessibility label while photo of front of driver's license is uploading"
            )
        case (.drivingLicense, .back):
            return STPLocalizedString(
                "Uploading back driver's license photo",
                "Accessibility label while photo of back of driver's license is uploading"
            )
        case (.idCard, .front):
            return STPLocalizedString(
                "Uploading front identity card photo",
                "Accessibility label while photo of front of identity card is uploading"
            )
        case (.idCard, .back):
            return STPLocalizedString(
                "Uploading back identity card photo",
                "Accessibility label while photo of back of identity card is uploading"
            )
        }
    }

    func uploadCompleteAccessibilityLabel(for side: DocumentSide) -> String {
        switch (documentType, side) {
        case (.passport, _):
            return STPLocalizedString(
                "Passport photo successfully uploaded",
                "Accessibility label when passport photo has successfully uploaded"
            )
        case (.drivingLicense, .front):
            return STPLocalizedString(
                "Front driver's license photo successfully uploaded",
                "Accessibility label when front driver's license photo has successfully uploaded"
            )
        case (.drivingLicense, .back):
            return STPLocalizedString(
                "Back driver's license photo successfully uploaded",
                "Accessibility label when back driver's license photo has successfully uploaded"
            )
        case (.idCard, .front):
            return STPLocalizedString(
                "Front identity card photo successfully uploaded",
                "Accessibility label when front identity card photo has successfully uploaded"
            )
        case (.idCard, .back):
            return STPLocalizedString(
                "Back identity card photo successfully uploaded",
                "Accessibility label when back identity card photo has successfully uploaded"
            )
        }
    }
}
