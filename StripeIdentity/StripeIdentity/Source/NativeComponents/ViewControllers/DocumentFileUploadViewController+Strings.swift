//
//  DocumentFileUploadViewController+Strings.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/4/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

extension DocumentFileUploadViewController {
    func listItemText(for side: DocumentSide, availableIDTypes: [String]) -> String {
        return side.instruction(availableIDTypes: availableIDTypes)
    }

    func accessibilityLabel(
        for side: DocumentSide,
        uploadStatus: DocumentUploader.UploadStatus,
        availableIDTypes: [String]
    ) -> String {
        switch uploadStatus {
        case .notStarted,
            .error:
            return selectAccessibilityLabel(for: side, availableIDTypes: availableIDTypes)
        case .inProgress:
            return uploadingAccessibilityLabel(for: side, availableIDTypes: availableIDTypes)
        case .complete:
            return uploadCompleteAccessibilityLabel(for: side, availableIDTypes: availableIDTypes)
        }
    }

    func selectAccessibilityLabel(for side: DocumentSide, availableIDTypes: [String]) -> String {
        
        func baseCase() -> String {
            switch side {
            case .front:
                return STPLocalizedString(
                    "Select front identity document photo",
                    "Accessibility label to select a photo of front of identity document"
                )
            case .back:
                return STPLocalizedString(
                    "Select back identity document photo",
                    "Accessibility label to select a photo of back of identity document"
                )
            }
        }
        
        if availableIDTypes.count == 1, let idType = availableIDTypes[0].uiIDType() {
            switch side {
            case .front:
                return String(format: STPLocalizedString(
                    "Select front %@ photo",
                    "Accessibility label to select a photo of front of driver's license, passport, or government issued photo id"
                ), idType)
            case .back:
                return String(format: STPLocalizedString(
                    "Select back %@ photo",
                    "Accessibility label to select a photo of back of driver's license, passport, or government issued photo id"
                ), idType)
            }
        }
        
        return baseCase()
    }

    func uploadingAccessibilityLabel(for side: DocumentSide, availableIDTypes: [String]) -> String {
        
        func baseCase() -> String {
            switch side {
            case .front:
                return STPLocalizedString(
                    "Uploading front identity document photo",
                    "Accessibility label while photo of front of identity document is uploading"
                )
            case .back:
                return STPLocalizedString(
                    "Uploading back identity document photo",
                    "Accessibility label while photo of back of identity document is uploading"
                )
            }
        }
        
        if availableIDTypes.count == 1, let idType = availableIDTypes[0].uiIDType() {
            switch side {
            case .front:
                return String(format: STPLocalizedString(
                    "Uploading front %@ photo",
                    "Accessibility label while photo of front of driver's license, passport, or government issued photo id is uploading"
                ), idType)
            case .back:
                return String(format: STPLocalizedString(
                    "Uploading back %@ photo",
                    "Accessibility label while photo of back of driver's license, passport, or government issued photo id is uploading"
                ), idType)
            }
        }
        
        return baseCase()
    }

    func uploadCompleteAccessibilityLabel(for side: DocumentSide, availableIDTypes: [String]) -> String {
        
        func baseCase() -> String {
            switch side {
            case .front:
                return STPLocalizedString(
                    "Front identity document photo successfully uploaded",
                    "Accessibility label when front identity document photo has successfully uploaded"
                )
            case .back:
                return STPLocalizedString(
                    "Back identity card photo successfully uploaded",
                    "Accessibility label when back identity card photo has successfully uploaded"
                )
            }
        }
        
        if availableIDTypes.count == 1, let idType = availableIDTypes[0].uiIDType() {
            switch side {
            case .front:
                return String(format: STPLocalizedString(
                    "Front %@ photo successfully uploaded",
                    "Accessibility label when front driver's license, passport, or government issued photo id photo has successfully uploaded"
                ), idType)
            case .back:
                return String(format: STPLocalizedString(
                    "Back %@ photo successfully uploaded",
                    "Accessibility label when back driver's license, passport, or government issued photo id photo photo has successfully uploaded"
                ), idType)
            }
        }
        
        return baseCase()
    }
}
