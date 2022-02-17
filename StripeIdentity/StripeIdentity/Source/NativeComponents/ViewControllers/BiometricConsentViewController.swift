//
//  BiometricConsentViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/29/21.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

final class BiometricConsentViewController: IdentityFlowViewController {

    private let htmlView = IdentityHTMLView()

    let merchantLogo: UIImage
    let consentContent: VerificationPageStaticContentConsentPage

    private var isSaving = false {
        didSet {
            updateUI()
        }
    }

    var flowViewModel: IdentityFlowView.ViewModel {

        // Display loading indicator on user's selection while saving
        let acceptButtonState: IdentityFlowView.ViewModel.Button.State
        let declineButtonState: IdentityFlowView.ViewModel.Button.State

        switch (isSaving, sheetController?.dataStore.biometricConsent) {
        case (true, true):
            acceptButtonState = .loading
            declineButtonState = .disabled
        case (true, false):
            acceptButtonState = .disabled
            declineButtonState = .loading
        default:
            acceptButtonState = .enabled
            declineButtonState = .enabled
        }

        return .init(
            headerViewModel: .init(
                backgroundColor: IdentityUI.containerColor,
                headerType: .banner(iconViewModel: .init(
                    iconType: .brand,
                    iconImage: merchantLogo,
                    iconImageContentMode: .scaleToFill
                )),
                titleText: consentContent.title
            ),
            contentViewModel: .init(
                view: htmlView,
                inset: .init(top: 32, leading: 16, bottom: 8, trailing: 16)
            ),
            buttons: [
                .init(
                    text: consentContent.acceptButtonText,
                    state: acceptButtonState,
                    didTap: { [weak self] in
                        self?.didTapButton(consentValue: true)
                    }
                ),
                .init(
                    text: consentContent.declineButtonText,
                    state: declineButtonState,
                    didTap: { [weak self] in
                        self?.didTapButton(consentValue: false)
                    }
                )
            ]
        )
    }

    init(
        merchantLogo: UIImage,
        consentContent: VerificationPageStaticContentConsentPage,
        sheetController: VerificationSheetControllerProtocol
    ) throws {
        self.merchantLogo = merchantLogo
        self.consentContent = consentContent
        super.init(sheetController: sheetController)

        // If HTML fails to render, throw error since it's unacceptable to not
        // display consent copy
        try htmlView.configure(with: .init(
            iconText: .init(
                image: Image.iconClock.makeImage(),
                text: STPLocalizedString(
                    "Takes about 1–2 minutes",
                    "Overview of how long it will take to complete Identity verification flow"
                )
            ),
            htmlString: consentContent.body,
            didOpenURL: { [weak self] url in
                self?.openInSafariViewController(url: url)
            }
        ))

        updateUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension BiometricConsentViewController {

    func updateUI() {
        configure(
            backButtonTitle: STPLocalizedString(
                "Consent",
                "Back button title for returning to consent screen of Identity verification"
            ),
            viewModel: flowViewModel
        )
    }

    func didTapButton(consentValue: Bool) {
        isSaving = true

        sheetController?.dataStore.biometricConsent = consentValue
        sheetController?.saveData { [weak sheetController] apiContent in
            guard let sheetController = sheetController else { return }
            sheetController.flowController.transitionToNextScreen(
                apiContent: apiContent,
                sheetController: sheetController,
                completion: { [weak self] in
                    self?.isSaving = false
                }
            )
        }
    }
}
