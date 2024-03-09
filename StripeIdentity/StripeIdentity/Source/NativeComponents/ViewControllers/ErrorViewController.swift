//
//  ErrorViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/4/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class ErrorViewController: IdentityFlowViewController {
    enum Model {
        case error(Error)
        case inputError(StripeAPI.VerificationPageDataRequirementError)
    }

    private let errorView = ErrorView()
    let model: Model
    private var isSaving: Bool = false {
        didSet {
            self.updateButtons()
        }
    }
    private var isFirstViewController: Bool = false
    var buttonViewModels: [IdentityFlowView.ViewModel.Button] {
        var buttons: [IdentityFlowView.ViewModel.Button] = []
        switch model {
        case .inputError(let inputError):
            guard let backButtonText = inputError.backButtonText else {
                fallthrough
            }

            if let continueButtonText = inputError.continueButtonText, inputError.requirement.supportsForceConfirm() {
                buttons.append(
                    .init(
                        text: continueButtonText,
                        state: isSaving ? .loading : .enabled,
                        isPrimary: false,
                        didTap: {
                            self.didTapContinueButton(requirementToForceCofirm: inputError.requirement)
                        }
                    )
                )
            }
            buttons.append(
                .init(
                    text: backButtonText,
                    state: isSaving ? .disabled : .enabled,
                    isPrimary: true,
                    didTap: self.didTapBackButton
                )
            )
        case .error:
            buttons.append(
                .init(
                    text: isFirstViewController ? String.Localized.close : STPLocalizedString(
                        "Go Back",
                        "Button to go back to the previous screen"
                    ),
                    state: .enabled,
                    isPrimary: true,
                    didTap: self.didTapBackButton
                )
            )
        }
        return buttons
    }

    init(
        sheetController: VerificationSheetControllerProtocol,
        error model: Model,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) {
        self.model = model
        super.init(sheetController: sheetController, analyticsScreenName: .error)
        logError(filePath: filePath, line: line)
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        errorView.configure(
            with: .init(
                titleText: model.title ?? String.Localized.error,
                bodyText: model.body
            )
        )

        // This error screen will be the first screen in the navigation
        // stack if the only screen before it is the loading screen. The loading
        // screen will be removed from the stack after the animation has finished.
        isFirstViewController =
            navigationController?.viewControllers.first === self
            || (navigationController?.viewControllers.first is LoadingViewController
                && navigationController?.viewControllers.stp_boundSafeObject(at: 1) === self)
        updateButtons()
    }

    private func updateButtons() {
        configure(
            backButtonTitle: String.Localized.error,
            viewModel: .init(
                headerViewModel: nil,
                contentViewModel: .init(view: errorView, inset: .zero),
                buttons: buttonViewModels
            )
        )
    }
}

extension ErrorViewController {
    fileprivate func didTapBackButton() {
        // If this is the only view in the stack, dismiss the nav controller
        guard navigationController?.viewControllers.first !== self else {
            dismiss(animated: true, completion: nil)
            return
        }

        switch model {

        case .inputError(let inputError):
            if sheetController?.flowController.canPopToScreen(withField: inputError.requirement)
                == true
            {
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

    fileprivate func didTapContinueButton(requirementToForceCofirm: StripeAPI.VerificationPageFieldType) {
        self.isSaving = true
        if requirementToForceCofirm == .idDocumentFront {
            self.sheetController?.forceDocumentFrontAndDecideBack(from: .error) { isBackRequired in
                self.isSaving = false
                if isBackRequired {
                    // popTo either Upload or Capture screen without resetting to continue from back
                    self.sheetController?.flowController.popToScreen(
                        withField: .idDocumentFront,
                        shouldResetViewController: false
                    )
                }
               // otherwise already checkSubmitAndTransition
            }
        } else if requirementToForceCofirm == .idDocumentBack {
            self.sheetController?.forceDocumentBackAndTransition(from: .error) {
                self.isSaving = false
            }
        }
        // no other values possible, only idDocumentFront and idDocumentBack supports forceConfirm

    }

    fileprivate func logError(filePath: StaticString, line: UInt) {
        guard case .error(let error) = model else {
            return
        }
        if let sheetController = sheetController {
            sheetController.analyticsClient.logGenericError(
                error: error,
                filePath: filePath,
                line: line,
                sheetController: sheetController
            )
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
