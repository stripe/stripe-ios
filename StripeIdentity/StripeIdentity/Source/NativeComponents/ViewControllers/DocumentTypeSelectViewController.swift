//
//  DocumentTypeSelectViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/5/21.
//

import UIKit
@_spi(STP) import StripeCore

final class DocumentTypeSelectViewController: IdentityFlowViewController {

    typealias DocumentType = VerificationPageDataIDDocument.DocumentType

    struct DocumentTypeAndLabel: Equatable {
        let documentType: DocumentType
        let label: String
    }

    // TODO(mludowise|IDPROD-2782): Use a view that matches design instead of a stackView with basic buttons
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8

        documentTypeWithLabels.forEach { documentTypeAndLabel in
            let button = ButtonWithTapHandler(onTap: { [weak self] in
                self?.didTapButton(documentType: documentTypeAndLabel.documentType)
            })
            button.setTitle(documentTypeAndLabel.label, for: .normal)
            button.setTitleColor(.systemBlue, for: .normal)
            stackView.addArrangedSubview(button)
        }

        return stackView
    }()

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

    let staticContent: VerificationPageStaticContentDocumentSelectPage

    init(sheetController: VerificationSheetControllerProtocol,
         staticContent: VerificationPageStaticContentDocumentSelectPage) {

        self.staticContent = staticContent
        super.init(sheetController: sheetController)

        // TODO(mludowise|IDPROD-2782): Update & localize text when design is finalized
        configure(
            title: staticContent.title,
            backButtonTitle: "Select ID",
            viewModel: .init(
                contentView: stackView,
                buttons: []
            )
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


extension DocumentTypeSelectViewController {
    func didTapButton(documentType: DocumentType) {
        sheetController?.dataStore.idDocumentType = documentType
        sheetController?.saveData { [weak sheetController] apiContent in
            guard let sheetController = sheetController else { return }
            sheetController.flowController.transitionToNextScreen(
                apiContent: apiContent,
                sheetController: sheetController
            )
        }
    }
}

// TODO(mludowise|IDPROD-2782): This is a temporary helper class to add button tap actions and should be replaced with a reusable component that matches the design
private class ButtonWithTapHandler: UIButton {
    let tapHandler: () -> Void

    init(onTap: @escaping () -> Void) {
        self.tapHandler = onTap
        super.init(frame: .zero)

        addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTap() {
        tapHandler()
    }
}

extension DocumentTypeSelectViewController.DocumentType {
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
