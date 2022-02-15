//
//  BiometricConsentViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/29/21.
//

import UIKit
@_spi(STP) import StripeCore

final class BiometricConsentViewController: IdentityFlowViewController {

    // TODO(mludowise|IDPROD-2755): Use a view that matches design instead of a label
    let bodyLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    init(sheetController: VerificationSheetControllerProtocol,
         consentContent: VerificationPageStaticContentConsentPage) {
        super.init(sheetController: sheetController)

        bodyLabel.text = consentContent.body

        // TODO(mludowise|IDPROD-2755): Text will eventually come from backend
        // response that's been localized.
        // TODO(jaimepark|IDPROD-2755): Update header view to match design
        configure(
            backButtonTitle: "Consent",
            viewModel: .init(
                headerViewModel: .init(
                    backgroundColor: IdentityUI.containerColor,
                    headerType: .banner(iconViewModel: nil),
                    titleText: "Identification Consent"
                ),
                contentView:  bodyLabel,
                buttonText: consentContent.acceptButtonText,
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

private extension BiometricConsentViewController {
    func didTapButton() {
        // TODO: disable button / show activity indicator
        sheetController?.dataStore.biometricConsent = true
        sheetController?.saveData { [weak sheetController] apiContent in
            guard let sheetController = sheetController else { return }
            sheetController.flowController.transitionToNextScreen(
                apiContent: apiContent,
                sheetController: sheetController,
                completion: {
                    // TODO: re-enable button / hide activity indicator
                }
            )
        }
    }
}
