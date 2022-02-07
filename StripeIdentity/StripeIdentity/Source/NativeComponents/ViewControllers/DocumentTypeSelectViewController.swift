//
//  DocumentTypeSelectViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/5/21.
//

import UIKit
@_spi(STP) import StripeCore

final class DocumentTypeSelectViewController: IdentityFlowViewController {

    // MARK: DocumentType

    typealias DocumentType = VerificationPageDataIDDocument.DocumentType

    struct DocumentTypeAndLabel: Equatable {
        let documentType: DocumentType
        let label: String
    }

    var documentTypeWithLabels: [DocumentTypeAndLabel] {
        /*
         Translate the dictionary returned by the server into a `DocumentType`
         with a display label.

         The results should be:
         - Sorted by display order
         - Filtered such that document types recognized by the client are represented

         If there are no document types recognized by the client, default to
         displaying all document types as valid options.
         */

        let fromServer: [DocumentTypeAndLabel] = DocumentType.allCases.compactMap {
            guard let label = staticContent.idDocumentTypeAllowlist[$0.rawValue] else {
                return nil
            }
            return DocumentTypeAndLabel(documentType: $0, label: label)
        }
        guard fromServer.isEmpty else {
            return fromServer
        }

        // If no valid `DocumentType` was returned by the server, then default to all types
        return DocumentType.allCases.map {
            DocumentTypeAndLabel(documentType: $0, label: $0.defaultLabel)
        }
    }

    // MARK: UI

    private let listView = ListView()

    var listViewModel: ListView.ViewModel {
        let items: [ListItemView.ViewModel] = documentTypeWithLabels.map { documentTypeAndLabel in
            // Don't make the row tappable if we're actively saving the document
            var tapHandler: (() -> Void)?
            if currentlySavingSelectedDocument == nil {
                tapHandler = { [weak self] in
                    self?.didTapOption(documentType: documentTypeAndLabel.documentType)
                }
            }

            // Display loading indicator if we're currently saving
            var accessoryViewModel: ListItemView.ViewModel.Accessory? = nil
            if currentlySavingSelectedDocument == documentTypeAndLabel.documentType {
                accessoryViewModel = .activityIndicator
            }

            return ListItemView.ViewModel(
                text: documentTypeAndLabel.label,
                accessory: accessoryViewModel,
                onTap: tapHandler
            )
        }
        return .init(items: items)
    }

    // Gets set to user-selected document type.
    // After selection is saved, is reset to nil.
    private(set) var currentlySavingSelectedDocument: DocumentType? = nil {
        didSet {
            guard oldValue != currentlySavingSelectedDocument else {
                return
            }
            listView.configure(with: listViewModel)
        }
    }

    // MARK: - Configuration

    let staticContent: VerificationPageStaticContentDocumentSelectPage

    init(sheetController: VerificationSheetControllerProtocol,
         staticContent: VerificationPageStaticContentDocumentSelectPage) {

        self.staticContent = staticContent
        super.init(sheetController: sheetController)

        listView.configure(with: listViewModel)
        // TODO(IDPROD-3130): Configure horizontal insets to 12pt inside flowView
        configure(
            title: staticContent.title,
            backButtonTitle: STPLocalizedString("ID Type", "Back button title to go back to screen to select form of identification (driver's license, passport, etc) to verify someone's identity"),
            viewModel: .init(
                contentView: listView,
                buttons: []
            )
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func didTapOption(documentType: DocumentType) {
        // Disable tap and show activity indicator while we're saving
        currentlySavingSelectedDocument = documentType

        sheetController?.dataStore.idDocumentType = documentType
        sheetController?.saveData { [weak self, weak sheetController] apiContent in
            guard let sheetController = sheetController else { return }
            sheetController.flowController.transitionToNextScreen(
                apiContent: apiContent,
                sheetController: sheetController
            )

            // Re-enable tap & stop activity indicator so the user can make a
            // different selection if they come back to this screen after
            // hitting the back button.
            self?.currentlySavingSelectedDocument = nil
        }
    }
}

// MARK: - Default Labels

private extension DocumentTypeSelectViewController.DocumentType {
    // Label to display for each document type if the server doesn't return one
    var defaultLabel: String {
        switch self {
        case .passport:
            return String.Localized.passport
        case .drivingLicense:
            return String.Localized.driving_license
        case .idCard:
            return String.Localized.id_card
        }
    }
}
