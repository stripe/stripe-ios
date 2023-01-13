//
//  BiometricConsentViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/29/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
final class BiometricConsentViewController: IdentityFlowViewController {

    private let htmlView = HTMLViewWithIconLabels()

    let brandLogo: UIImage
    let consentContent: StripeAPI.VerificationPageStaticContentConsentPage

    private var consentSelection: Bool?

    private var isSaving = false {
        didSet {
            updateUI()
        }
    }

    var scrolledToBottom = false {
        didSet {
            updateUI()
        }
    }

    private var scrolledToBottomYOffset: CGFloat?

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

        var buttons: [IdentityFlowView.ViewModel.Button] = []
        if scrolledToBottom {
            buttons.append(
                .init(
                    text: consentContent.acceptButtonText,
                    state: acceptButtonState,
                    didTap: { [weak self] in
                        self?.didTapButton(consentValue: true)
                    }
                )
            )
        } else {
            buttons.append(
                .init(
                    text: consentContent.scrollToContinueButtonText,
                    state: .disabled,
                    didTap: {}
                )
            )
        }
        buttons.append(
            .init(
                text: consentContent.declineButtonText,
                state: declineButtonState,
                didTap: { [weak self] in
                    self?.didTapButton(consentValue: false)
                }
            )
        )

        return .init(
            headerViewModel: .init(
                backgroundColor: .systemBackground,
                headerType: .banner(
                    iconViewModel: .init(
                        iconType: .brand,
                        iconImage: brandLogo,
                        iconImageContentMode: .scaleToFill
                    )
                ),
                titleText: consentContent.title
            ),
            contentViewModel: .init(
                view: htmlView,
                inset: .init(top: 16, leading: 16, bottom: 8, trailing: 16)
            ),
            buttons: buttons,
            scrollViewDelegate: self,
            flowViewDelegate: self
        )
    }

    init(
        brandLogo: UIImage,
        consentContent: StripeAPI.VerificationPageStaticContentConsentPage,
        sheetController: VerificationSheetControllerProtocol
    ) throws {
        self.brandLogo = brandLogo
        self.consentContent = consentContent
        super.init(sheetController: sheetController, analyticsScreenName: .biometricConsent)

        // If HTML fails to render, throw error since it's unacceptable to not
        // display consent copy
        try htmlView.configure(
            with: .init(
                iconText: [
                    .init(
                        image: Image.iconClock.makeImage().withTintColor(IdentityUI.iconColor),
                        text: consentContent.timeEstimate,
                        isTextHTML: false
                    ),
                ],
                nonIconText: [
                    .init(
                        text: consentContent.privacyPolicy,
                        isTextHTML: true
                    ),
                ],
                bodyHtmlString: consentContent.body,
                didOpenURL: { [weak self] url in
                    self?.openInSafariViewController(url: url)
                }
            )
        )

        updateUI()
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Private Helpers

@available(iOSApplicationExtension, unavailable)
extension BiometricConsentViewController {

    fileprivate func updateUI() {
        configure(
            backButtonTitle: STPLocalizedString(
                "Consent",
                "Back button title for returning to consent screen of Identity verification"
            ),
            viewModel: flowViewModel
        )
    }

    fileprivate func didTapButton(consentValue: Bool) {
        consentSelection = consentValue
        isSaving = true
        sheetController?.saveAndTransition(
            from: analyticsScreenName,
            collectedData: .init(
                biometricConsent: consentValue
            )
        ) { [weak self] in
            self?.isSaving = false
        }
    }
}

// MARK: - IdentityDataCollecting

@available(iOSApplicationExtension, unavailable)
extension BiometricConsentViewController: IdentityDataCollecting {
    var collectedFields: Set<StripeAPI.VerificationPageFieldType> {
        return [.biometricConsent]
    }
}

// MARK: - UIScrollViewDelegate
@available(iOS 13, *)
@available(iOSApplicationExtension, unavailable)
extension BiometricConsentViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let scrolledToBottomYOffset = scrolledToBottomYOffset,
            scrollView.contentOffset.y > scrolledToBottomYOffset
        {
            scrolledToBottom = true
        }
    }
}

// MARK: - IdentityFlowViewDelegate
@available(iOS 13, *)
@available(iOSApplicationExtension, unavailable)
extension BiometricConsentViewController: IdentityFlowViewDelegate {
    func scrollViewFullyLaiedOut(_ scrollView: UIScrollView) {
        guard scrolledToBottomYOffset == nil else {
            return
        }

        let initialContentYOffset = scrollView.contentOffset.y
        let contentSizeHeight = scrollView.contentSize.height
        let visibleContentHeight =
            scrollView.frame.size.height + initialContentYOffset - scrollView.contentInset.bottom
        let nonVisibleContentHeight = contentSizeHeight - visibleContentHeight
        scrolledToBottomYOffset = initialContentYOffset + nonVisibleContentHeight

        // all content is visible, not scrollable
        if visibleContentHeight > contentSizeHeight {
            scrolledToBottom = true
        }
    }
}
