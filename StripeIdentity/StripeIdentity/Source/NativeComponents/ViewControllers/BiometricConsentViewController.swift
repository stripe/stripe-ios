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

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 24
        return stackView
    }()

    private let multilineContent = MultilineIconLabelHTMLView()
    private let privacyPolicyView = HTMLTextView()

    let brandLogo: UIImage
    let showsStripeLogo: Bool
    let consentContent: StripeAPI.VerificationPageStaticContentConsentPage
    let configuration: IdentityVerificationSheet.Configuration.BiometricConsentConfiguration?

    private let networkedIdentity: NetworkedIdentityPresenter?
    private lazy var linkEntryChip = LinkSavedIdChipView { [weak self] in self?.didDismissLinkEntry() }
    private var isLinkEntryVisible = true

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
        if scrolledToBottom, let networkedIdentity, networkedIdentity.entry.offersReuse, isLinkEntryVisible {
            // Networked Identity "Integrated on intro": sharing a saved ID also accepts consent.
            buttons.append(
                .init(
                    text: "Continue with Link",
                    state: acceptButtonState,
                    didTap: { [weak self] in
                        guard let self else { return }
                        networkedIdentity.startReuse(from: self) { [weak self] outcome in
                            self?.didFinishNetworkedIdentity(outcome)
                        }
                    }
                )
            )
            buttons.append(
                .init(
                    text: "Manually verify instead",
                    state: acceptButtonState == .loading ? .disabled : acceptButtonState,
                    isPrimary: false,
                    didTap: { [weak self] in
                        guard let self else { return }
                        self.consentSelection = true
                        self.isSaving = true
                        networkedIdentity.chooseManualCapture(from: self) { [weak self] outcome in
                            self?.didFinishNetworkedIdentity(outcome)
                        }
                    }
                )
            )
        } else if scrolledToBottom {
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
                    if configuration?.hideBrandingHeader == true
                        || sheetController?.flowController.visitedIndividualWelcomePage == true
                    {
                        return .plain
                    } else {
                        // Otherwise this is the first screen, show icons
                        return .banner(
                            iconViewModel: .init(
                                iconType: showsStripeLogo ? .brand : .plain,
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
                view: contentStackView,
                inset: .init(top: Style.contentTopPadding, leading: Style.contentHorizontalPadding, bottom: Style.contentBottomPadding, trailing: Style.contentHorizontalPadding)
            ),
            buttons: buttons,
            scrollViewDelegate: self,
            flowViewDelegate: self,
            buttonTopAccessoryView: networkedIdentity == nil ? nil : linkEntryChip
        )
    }

    init(
        brandLogo: UIImage,
        showsStripeLogo: Bool,
        consentContent: StripeAPI.VerificationPageStaticContentConsentPage,
        configuration: IdentityVerificationSheet.Configuration.BiometricConsentConfiguration? = nil,
        networkedIdentity: NetworkedIdentityPresenter? = nil,
        sheetController: VerificationSheetControllerProtocol
    ) throws {
        self.brandLogo = brandLogo
        self.showsStripeLogo = showsStripeLogo
        self.consentContent = consentContent
        self.configuration = configuration
        self.networkedIdentity = networkedIdentity.flatMap { $0.entry.reuseAvailable ? $0 : nil }
        super.init(sheetController: sheetController, analyticsScreenName: .biometricConsent)

        // Set up the content stack view with both main content and privacy policy
        setupContentStackView()

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

        // Configure privacy policy content to be part of scrollable content
        try privacyPolicyView.configure(
            with: .init(
                text: consentContent.privacyPolicy,
                style: .html(makeStyle: IdentityFlowView.privacyPolicyLineContentStyle),
                didOpenURL: { [weak self] url in
                    self?.openInSafariViewController(url: url)
                }
            )
        )

        updateUI()
        networkedIdentity?.onEntryChange = { [weak self] in
            self?.renderLinkEntryChip()
            self?.updateUI()
        }
        networkedIdentity?.refreshEntry()
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContentStackView() {
        renderLinkEntryChip()
        contentStackView.addArrangedSubview(multilineContent)

        // Create a container for the privacy policy with centered alignment
        let privacyPolicyContainer = UIView()
        privacyPolicyContainer.addSubview(privacyPolicyView)
        privacyPolicyView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            privacyPolicyView.topAnchor.constraint(equalTo: privacyPolicyContainer.topAnchor),
            privacyPolicyView.leadingAnchor.constraint(greaterThanOrEqualTo: privacyPolicyContainer.leadingAnchor),
            privacyPolicyView.trailingAnchor.constraint(lessThanOrEqualTo: privacyPolicyContainer.trailingAnchor),
            privacyPolicyView.centerXAnchor.constraint(equalTo: privacyPolicyContainer.centerXAnchor),
            privacyPolicyView.bottomAnchor.constraint(equalTo: privacyPolicyContainer.bottomAnchor),
        ])

        contentStackView.addArrangedSubview(privacyPolicyContainer)
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

    /// Without a known account there's no chip; the sheet asks for the email instead.
    fileprivate func renderLinkEntryChip() {
        let email = networkedIdentity?.entry.accountEmail
        linkEntryChip.email = email
        linkEntryChip.isHidden = email == nil || !isLinkEntryVisible
    }

    fileprivate func didDismissLinkEntry() {
        isLinkEntryVisible = false
        linkEntryChip.isHidden = true
        updateUI()
    }

    fileprivate func didFinishNetworkedIdentity(_ outcome: NetworkedIdentityOutcome) {
        switch outcome {
        case .documentShared(_, let attached), .manualCapture(let attached):
            // Sharing a saved ID also accepts consent.
            consentSelection = true
            isSaving = true
            sheetController?.saveConsentAfterNetworkedIdentity(attached: attached) { [weak self] in
                self?.isSaving = false
            }
        case .fallback:
            didTapButton(consentValue: true)
        case .cancelled, .savePrepared:
            isSaving = false
        }
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

/// Networked Identity: the saved ID chip shown above the intro buttons, matching Android's `LinkSavedIdChip`.
private final class LinkSavedIdChipView: UIView {
    private let label = UILabel()
    private let onDismiss: () -> Void

    var email: String? {
        didSet {
            // #TODO - Networked Identity: localize once the final mobile copy is approved.
            label.text = email.map { "Saved ID · \($0)" } ?? "Saved ID"
        }
    }

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        super.init(frame: .zero)

        let logoView = UIImageView(image: Image.linkLogo.makeImage())
        logoView.contentMode = .scaleAspectFit
        logoView.isAccessibilityElement = true
        logoView.accessibilityLabel = "Link"

        label.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 14))
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        label.numberOfLines = 0

        let dismissButton = UIButton(type: .system)
        dismissButton.setImage(
            UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)),
            for: .normal
        )
        dismissButton.tintColor = .label
        dismissButton.accessibilityLabel = "Dismiss"
        dismissButton.addAction(UIAction { [weak self] _ in self?.onDismiss() }, for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [logoView, label, dismissButton])
        row.alignment = .center
        row.spacing = 8
        row.setCustomSpacing(0, after: label)
        addAndPinSubview(row, insets: .init(top: 0, leading: 12, bottom: 0, trailing: 0))

        NSLayoutConstraint.activate([
            logoView.widthAnchor.constraint(equalToConstant: 40),
            logoView.heightAnchor.constraint(equalToConstant: 16),
            dismissButton.widthAnchor.constraint(equalToConstant: 48),
            dismissButton.heightAnchor.constraint(equalToConstant: 48),
        ])
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)

        layer.cornerRadius = 12
        layer.borderWidth = 1
        updateBorderColor()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateBorderColor()
    }

    private func updateBorderColor() {
        layer.borderColor = UIColor.label.withAlphaComponent(0.15).resolvedColor(with: traitCollection).cgColor
    }
}
