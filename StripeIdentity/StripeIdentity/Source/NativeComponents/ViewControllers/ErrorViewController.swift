//
//  ErrorViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/4/21.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

final class ErrorViewController: IdentityFlowViewController {
    enum Model {
        case error(Error)
        case inputError(VerificationPageDataRequirementError)
    }

    private let errorView = ErrorView()
    let model: Model

    init(sheetController: VerificationSheetControllerProtocol,
         error model: Model) {
        self.model = model
        super.init(sheetController: sheetController)

        errorView.configure(with: .init(titleText: model.title ?? String.Localized.error, bodyText: model.body))
        // TODO(IDPROD-2747): Localize and update to match design when finalized
        configure(
            backButtonTitle: String.Localized.error,
            viewModel: .init(
                headerViewModel: nil,
                contentViewModel: .init(view: errorView, inset: .zero),
                buttons: [
                    .init(
                        text: model.buttonText,
                        state: .enabled,
                        isPrimary: true,
                        didTap: { [weak self] in
                            self?.didTapButton()
                        }
                    )
                ]
            )
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ErrorViewController {
    func didTapButton() {
        navigationController?.popViewController(animated: true)
    }
}

extension ErrorViewController.Model {
    var title: String? {
        switch self {
        case .error:
            return nil
        case .inputError(let inputError):
            return inputError.title
        }
    }

    var body: String {
        switch self {
        case .error(let error):
            return error.localizedDescription
        case .inputError(let inputError):
            return inputError.body
        }
    }

    var buttonText: String {
        // TODO(IDPROD-2747): Update to match design and localize
        switch self {
        case .inputError(let inputError):
            guard let buttonText = inputError.buttonText else {
                fallthrough
            }
            return buttonText
        case .error:
            return "Go Back"
        }
    }
}
