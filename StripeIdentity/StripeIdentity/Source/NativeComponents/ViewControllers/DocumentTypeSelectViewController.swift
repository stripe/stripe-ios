//
//  DocumentTypeSelectViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/5/21.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

enum DocumentTypeSelectViewControllerError: AnalyticLoggableError {
    case noValidDocumentTypes(providedDocumentTypes: [String])

    func serializeForLogging() -> [String : Any] {
        // TODO(mludowise|IDPROD-2816): Log error
        return [:]
    }
}

final class DocumentTypeSelectViewController: IdentityFlowViewController {

    // MARK: DocumentType

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
         */

        return DocumentType.allCases.compactMap {
            guard let label = staticContent.idDocumentTypeAllowlist[$0.rawValue] else {
                return nil
            }
            return DocumentTypeAndLabel(documentType: $0, label: label)
        }
    }

    // MARK: UI

    private let instructionListView = InstructionListView()

    var viewModel: InstructionListView.ViewModel {
        guard documentTypeWithLabels.count != 1 else {
            return .init(
                instructionText: staticContent.body,
                listViewModel: nil
            )
        }

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
                accessibilityLabel: nil,
                accessory: accessoryViewModel,
                onTap: tapHandler
            )
        }
        return .init(instructionText: nil, listViewModel: .init(items: items))
    }

    var buttonViewModel: IdentityFlowView.ViewModel.Button? {
        guard documentTypeWithLabels.count == 1 else {
            return nil
        }

        return .continueButton(
            state: (currentlySavingSelectedDocument != nil) ? .loading : .enabled,
            didTap: { [weak self] in
                guard let self = self else { return }
                self.didTapOption(documentType: self.documentTypeWithLabels[0].documentType)
            }
        )

    }

    // Gets set to user-selected document type.
    // After selection is saved, is reset to nil.
    private(set) var currentlySavingSelectedDocument: DocumentType? = nil {
        didSet {
            guard oldValue != currentlySavingSelectedDocument else {
                return
            }
            updateUI()
        }
    }

    // MARK: - Configuration

    let staticContent: VerificationPageStaticContentDocumentSelectPage

    init(sheetController: VerificationSheetControllerProtocol,
         staticContent: VerificationPageStaticContentDocumentSelectPage) throws {

        self.staticContent = staticContent
        super.init(sheetController: sheetController)

        guard !documentTypeWithLabels.isEmpty else {
            throw DocumentTypeSelectViewControllerError.noValidDocumentTypes(
                providedDocumentTypes: Array(staticContent.idDocumentTypeAllowlist.keys)
            )
        }

        updateUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateUI() {
        instructionListView.configure(with: viewModel)
        configure(
            backButtonTitle: STPLocalizedString(
                "ID Type",
                "Back button title to go back to screen to select form of identification (driver's license, passport, etc) to verify someone's identity"
            ),
            viewModel: .init(
                headerViewModel: .init(
                    backgroundColor: CompatibleColor.systemBackground,
                    headerType: .plain,
                    titleText: staticContent.title
                ),
                contentViewModel: .init(
                    view: instructionListView,
                    inset: .init(top: 32, leading: 0, bottom: 0, trailing: 0)
                ),
                buttons: buttonViewModel.map { [$0] } ?? []
            )
        )
    }

    func didTapOption(documentType: DocumentType) {
        // Disable tap and show activity indicator while we're saving
        currentlySavingSelectedDocument = documentType

        sheetController?.saveAndTransition(collectedData: .init(
            idDocumentType: documentType
        )) { [weak self] in
                // Re-enable tap & stop activity indicator so the user can
                // make a different selection if they come back to this
                // screen after hitting the back button.
                self?.currentlySavingSelectedDocument = nil
        }
    }
}

// MARK: - IdentityDataCollecting

extension DocumentTypeSelectViewController: IdentityDataCollecting {
    var collectedFields: Set<VerificationPageFieldType> {
        return [.idDocumentType]
    }
}
