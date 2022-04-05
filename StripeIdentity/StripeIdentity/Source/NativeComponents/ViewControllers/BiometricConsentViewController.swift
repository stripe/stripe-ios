//
//  BiometricConsentViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/29/21.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

@available(iOS 13, *)
@available(iOSApplicationExtension, unavailable)
final class BiometricConsentViewController: IdentityFlowViewController {

    private let htmlView = HTMLViewWithIconLabels()

    let brandLogo: UIImage
    let consentContent: VerificationPageStaticContentConsentPage

    private var consentSelection: Bool?

    private var isSaving = false {
        didSet {
            updateUI()
        }
    }

    var flowViewModel: IdentityFlowView.ViewModel {

        // Display loading indicator on user's selection while saving
        let acceptButtonState: IdentityFlowView.ViewModel.Button.State
        let declineButtonState: IdentityFlowView.ViewModel.Button.State

        switch (isSaving, consentSelection) {
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
                    iconImage: brandLogo,
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
        brandLogo: UIImage,
        consentContent: VerificationPageStaticContentConsentPage,
        sheetController: VerificationSheetControllerProtocol
    ) throws {
        self.brandLogo = brandLogo
        self.consentContent = consentContent
        super.init(sheetController: sheetController)

        // If HTML fails to render, throw error since it's unacceptable to not
        // display consent copy
        try htmlView.configure(with: .init(
            iconText: [
                .init(
                    image: Image.iconClock.makeImage().withTintColor(IdentityUI.iconColor),
                    text: consentContent.timeEstimate,
                    isTextHTML: false
                ),
                .init(
                    image: Image.iconInfo.makeImage().withTintColor(IdentityUI.iconColor),
                    text: consentContent.privacyPolicy,
                    isTextHTML: true
                ),
            ],
            bodyHtmlString: consentContent.body,
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

// MARK: - Private Helpers

@available(iOS 13, *)
@available(iOSApplicationExtension, unavailable)
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
        consentSelection = consentValue
        isSaving = true
        sheetController?.saveAndTransition(collectedData: .init(
            biometricConsent: consentValue
        )) { [weak self] in
            self?.isSaving = false
        }
    }
}

// MARK: - IdentityDataCollecting

@available(iOS 13, *)
@available(iOSApplicationExtension, unavailable)
extension BiometricConsentViewController: IdentityDataCollecting {
    var collectedFields: Set<VerificationPageFieldType> {
        return [.biometricConsent]
    }
}
