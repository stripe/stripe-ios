//
//  ErrorViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/4/21.
//

import UIKit
@_spi(STP) import StripeCore

final class ErrorViewController: IdentityFlowViewController {
    enum Model {
        case error(Error)
        case inputError(VerificationSessionDataRequirementError)
    }

    let bodyLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    let model: Model

    init(sheetController: VerificationSheetControllerProtocol,
         error model: Model) {
        self.model = model
        super.init(sheetController: sheetController)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let labelText = [model.title, model.body].compactMap { $0 }.joined(separator: "\n\n")
        bodyLabel.text = labelText


        // TODO(IDPROD-2747): Localize and update to match design when finalized
        configure(
            title: "Error",
            backButtonTitle: "Error",
            viewModel: .init(
                contentView: bodyLabel,
                buttonText: model.buttonText,
                didTapButton: { [weak self] in
                    self?.didTapButton()
                }
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
        case .error:
            return "Go Back"
        case .inputError(let inputError):
            return inputError.buttonText
        }
    }
}
