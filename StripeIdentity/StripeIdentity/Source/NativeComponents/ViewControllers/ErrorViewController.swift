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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        errorView.configure(with: .init(
            titleText: model.title ?? String.Localized.error,
            bodyText: model.body
        ))

        /*
         This error screen will be the first screen in the navigation
         stack if the only screen before it is the loading screen. The loading
         screen will be removed from the stack after the animation has finished.
         */
        let isFirstViewController = navigationController?.viewControllers.first === self
        || (navigationController?.viewControllers.first is LoadingViewController
            && navigationController?.viewControllers.stp_boundSafeObject(at: 1) === self)

        configure(
            backButtonTitle: String.Localized.error,
            viewModel: .init(
                headerViewModel: nil,
                contentViewModel: .init(view: errorView, inset: .zero),
                buttons: [
                    .init(
                        text: model.buttonText(
                            isFirstViewController: isFirstViewController
                        ),
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
}

private extension ErrorViewController {
    func didTapButton() {
        // If this is the only view in the stack, dismiss the nav controller
        guard navigationController?.viewControllers.first !== self else {
            dismiss(animated: true, completion: nil)
            return
        }

        switch model {

        case .inputError(let inputError):
            if sheetController?.flowController.canPopToScreen(withField: inputError.requirement) == true {
                // Attempt to go back to the view that has the error
                sheetController?.flowController.popToScreen(
                    withField: inputError.requirement,
                    shouldResetViewController: true
                )
            } else {
                // Go back to the previous view
                navigationController?.popViewController(animated: true)
            }

        case .error:
            // Go back to the previous view
            navigationController?.popViewController(animated: true)
        }
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

    func buttonText(isFirstViewController: Bool) -> String {
        switch self {
        case .inputError(let inputError):
            guard let buttonText = inputError.backButtonText else {
                fallthrough
            }
            return buttonText
        case .error:
            if isFirstViewController {
                return String.Localized.close
            } else {
                return STPLocalizedString(
                    "Go Back",
                    "Button to go back to the previous screen"
                )
            }
        }
    }
}
