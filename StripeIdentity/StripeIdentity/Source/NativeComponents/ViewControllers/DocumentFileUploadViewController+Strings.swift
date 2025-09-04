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
                return String.Localized.selectFrontIdentityDocumentPhoto
            case .back:
                return String.Localized.selectBackIdentityDocumentPhoto
            }
        }

        if availableIDTypes.count == 1, let idType = availableIDTypes[0].uiIDType() {
            switch side {
            case .front:
                return String(format: String.Localized.selectFrontSpecificDocumentPhoto, idType)
            case .back:
                return String(format: String.Localized.selectBackSpecificDocumentPhoto, idType)
            }
        }

        return baseCase()
    }

    func uploadingAccessibilityLabel(for side: DocumentSide, availableIDTypes: [String]) -> String {

        func baseCase() -> String {
            switch side {
            case .front:
                return String.Localized.uploadingFrontIdentityDocumentPhoto
            case .back:
                return String.Localized.uploadingBackIdentityDocumentPhoto
            }
        }

        if availableIDTypes.count == 1, let idType = availableIDTypes[0].uiIDType() {
            switch side {
            case .front:
                return String(format: String.Localized.uploadingFrontSpecificDocumentPhoto, idType)
            case .back:
                return String(format: String.Localized.uploadingBackSpecificDocumentPhoto, idType)
            }
        }

        return baseCase()
    }

    func uploadCompleteAccessibilityLabel(for side: DocumentSide, availableIDTypes: [String]) -> String {

        func baseCase() -> String {
            switch side {
            case .front:
                return String.Localized.frontIdentityDocumentPhotoUploadedSuccessfully
            case .back:
                return String.Localized.backIdentityDocumentPhotoUploadedSuccessfully
            }
        }

        if availableIDTypes.count == 1, let idType = availableIDTypes[0].uiIDType() {
            switch side {
            case .front:
                return String(format: String.Localized.frontSpecificDocumentPhotoUploadedSuccessfully, idType)
            case .back:
                return String(format: String.Localized.backSpecificDocumentPhotoUploadedSuccessfully, idType)
            }
        }

        return baseCase()
    }
}
