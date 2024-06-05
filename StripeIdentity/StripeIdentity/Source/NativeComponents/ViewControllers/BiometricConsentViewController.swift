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

final class BiometricConsentViewController: IdentityFlowViewController {

    private let multilineContent = MultilineIconLabelHTMLView()

    let brandLogo: UIImage
    let consentContent: StripeAPI.VerificationPageStaticContentConsentPage

    struct Style {
        static let contentHorizontalPadding: CGFloat = 32
        static let contentTopPadding: CGFloat = 16
        static let contentBottomPadding: CGFloat = 8
    }

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
                isPrimary: false,
                didTap: { [weak self] in
                    self?.didTapButton(consentValue: false)
                }
            )
        )

        return .init(
            headerViewModel: .init(
                backgroundColor: .systemBackground,
                headerType: {
                    if sheetController?.flowController.visitedIndividualWelcomePage == true {
                        // If visited individual page, this is a fallback. Don't show icons
                        return .plain
                    } else {
                        // Otherwise this is the first screen, show icons
                        return .banner(
                            iconViewModel: .init(
                                iconType: .brand,
                                iconImage: brandLogo,
                                iconImageContentMode: .scaleToFill,
                                useLargeIcon: true
                            )
                        )
                    }
                }(),
                titleText: consentContent.title
            ),
            contentViewModel: .init(
                view: multilineContent,
                inset: .init(top: Style.contentTopPadding, leading: Style.contentHorizontalPadding, bottom: Style.contentBottomPadding, trailing: Style.contentHorizontalPadding)
            ),
            buttons: buttons,
            buttonTopContentViewModel: .init(
                text: consentContent.privacyPolicy,
                style: .html(makeStyle: IdentityFlowView.privacyPolicyLineContentStyle),
                didOpenURL: { [weak self] url in
                    self?.openInSafariViewController(url: url)
                }
            ),
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
        try multilineContent.configure(
            with: .init(
                lines: consentContent.lines.map {
                    return ($0.icon, $0.content)
                }
            ) { [weak self] url in
                self?.presentBottomsheet(withUrl: url)
            }
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

extension BiometricConsentViewController: IdentityDataCollecting {
    var collectedFields: Set<StripeAPI.VerificationPageFieldType> {
        return [.biometricConsent]
    }
}

// MARK: - UIScrollViewDelegate
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
