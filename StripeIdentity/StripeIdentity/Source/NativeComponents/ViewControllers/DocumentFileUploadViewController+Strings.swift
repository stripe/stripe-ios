//
//  DocumentFileUploadViewController+Strings.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/4/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

extension DocumentFileUploadViewController {
    func listItemText(for side: DocumentSide) -> String {
        switch side {
        case .front:
            return STPLocalizedString(
                "Front of identity card",
                "Description of front of identity card image"
            )
        case .back:
            return STPLocalizedString(
                "Back of identity card",
                "Description of back of identity card image"
            )
        }
    }

    func accessibilityLabel(
        for side: DocumentSide,
        uploadStatus: DocumentUploader.UploadStatus
    ) -> String {
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
        switch side {
        case .front:
            return STPLocalizedString(
                "Select front identity card photo",
                "Accessibility label to select a photo of front of identity card"
            )
        case .back:
            return STPLocalizedString(
                "Select back identity card photo",
                "Accessibility label to select a photo of back of identity card"
            )
        }
    }

    func uploadingAccessibilityLabel(for side: DocumentSide) -> String {
        switch side {
        case .front:
            return STPLocalizedString(
                "Uploading front identity card photo",
                "Accessibility label while photo of front of identity card is uploading"
            )
        case .back:
            return STPLocalizedString(
                "Uploading back identity card photo",
                "Accessibility label while photo of back of identity card is uploading"
            )
        }
    }

    func uploadCompleteAccessibilityLabel(for side: DocumentSide) -> String {
        switch side {
        case .front:
            return STPLocalizedString(
                "Front identity card photo successfully uploaded",
                "Accessibility label when front identity card photo has successfully uploaded"
            )
        case .back:
            return STPLocalizedString(
                "Back identity card photo successfully uploaded",
                "Accessibility label when back identity card photo has successfully uploaded"
            )
        }
    }
}
