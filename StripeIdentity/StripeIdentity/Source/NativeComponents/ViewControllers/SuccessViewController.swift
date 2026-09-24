//
//  SuccessViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/16/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class SuccessViewController: IdentityFlowViewController {

    private let htmlView = HTMLViewWithIconLabels()
    private let networkedIdentity: NetworkedIdentityPresenter?
    private let saveCard = UIStackView()
    private weak var saveButtonLogo: UIImageView?

    init(
        successContent: StripeAPI.VerificationPageStaticContentTextPage,
        networkedIdentity: NetworkedIdentityPresenter? = nil,
        sheetController: VerificationSheetControllerProtocol
    ) {
        self.networkedIdentity = networkedIdentity.flatMap { $0.entry.offersSave ? $0 : nil }
        super.init(
            sheetController: sheetController,
            analyticsScreenName: .success,
            shouldShowCancelButton: false
        )

        do {
            // In practice, this shouldn't throw an error since HTML copy will
            // be vetted. But in the event that an error occurs parsing the HTML,
            // body text will be empty but user will still see success title and
            // button.
            try htmlView.configure(
                with: .init(
                    bodyHtmlString: successContent.body,
                    didOpenURL: { [weak self] url in
                        self?.openInSafariViewController(url: url)
                    }
                )
            )
        } catch {
            sheetController.analyticsClient.logGenericError(error: error, sheetController: sheetController)
        }

        configure(
            backButtonTitle: nil,
            viewModel: .init(
                headerViewModel: .init(
                    backgroundColor: .systemBackground,
                    headerType: .banner(
                        iconViewModel: .init(
                            iconType: .plain,
                            iconImage: Image.iconClock.makeImage(template: true),
                            iconImageContentMode: .center,
                            iconTintColor: .white,
                            shouldIconBackgroundMatchTintColor: true
                        )
                    ),
                    titleText: successContent.title
                ),
                contentView: self.networkedIdentity == nil ? htmlView : makeContentWithSaveCard(),
                buttonText: successContent.buttonText,
                didTapButton: { [weak self] in
                    self?.didTapButton()
                }
            )
        )
        self.networkedIdentity?.onEntryChange = { [weak self] in self?.renderSaveCard() }
        self.networkedIdentity?.refreshEntry()
    }

    /// Networked Identity "Button on success": offers saving this verification's ID to Link.
    private func makeContentWithSaveCard() -> UIView {
        saveCard.axis = .vertical
        saveCard.spacing = 12
        saveCard.isLayoutMarginsRelativeArrangement = true
        saveCard.layoutMargins = .init(top: 16, left: 16, bottom: 16, right: 16)
        saveCard.layer.cornerRadius = 12
        saveCard.layer.borderWidth = 1
        saveCard.layer.borderColor = UIColor.separator.cgColor
        renderSaveCard()

        let stack = UIStackView(arrangedSubviews: [htmlView, saveCard])
        stack.axis = .vertical
        stack.spacing = 24
        return stack
    }

    private func renderSaveCard() {
        guard let networkedIdentity else {
            return
        }
        saveCard.arrangedSubviews.forEach { $0.removeFromSuperview() }
        // Once saving is prepared, only the thank-you remains.
        saveCard.isHidden = networkedIdentity.hasPreparedSave
        guard !networkedIdentity.hasPreparedSave else {
            return
        }

        // #TODO - Networked Identity: localize once the final mobile copy is approved; the Figma copy is a placeholder.
        let title = UILabel()
        title.font = NetworkedIdentityUI.bodyEmphasizedFont
        title.numberOfLines = 0
        title.textAlignment = .center
        title.text = "Save for secure 1-click verification"

        let body = UILabel()
        body.font = NetworkedIdentityUI.captionFont
        body.textColor = .secondaryLabel
        body.numberOfLines = 0
        body.textAlignment = .center
        body.text = "Save it to Link, Stripe's consumer wallet, to reuse it with any business on our network."

        let whatIsLink = UIButton(type: .system)
        whatIsLink.setAttributedTitle(
            NSAttributedString(
                string: "What is Link?",
                attributes: [
                    .font: NetworkedIdentityUI.captionFont,
                    .foregroundColor: UIColor.secondaryLabel,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                ]
            ),
            for: .normal
        )
        whatIsLink.addTarget(self, action: #selector(didTapWhatIsLink), for: .touchUpInside)

        [title, body, makeSavedItemsRow(), whatIsLink, makeSaveButton()].forEach(saveCard.addArrangedSubview)
        saveCard.setCustomSpacing(4, after: title)
    }

    /// "Save ID with [Link logo]", centered. `Button` pins icons to its edges, so the title and logo are laid
    /// over an empty title that keeps the button's height.
    private func makeSaveButton() -> Button {
        let button = Button(configuration: .networkedIdentityPrimary(), title: " ")
        button.accessibilityLabel = "Save ID with Link"
        button.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)

        let label = UILabel()
        label.font = NetworkedIdentityUI.bodyEmphasizedFont
        label.textColor = .systemBackground
        label.text = "Save ID with"

        let logo = UIImageView(image: Image.linkLogo.makeImage())
        logo.contentMode = .scaleAspectFit
        // The button's background is the opposite of the screen's appearance, so is the logo.
        saveButtonLogo = logo
        updateSaveButtonLogoAppearance()
        let logoSize = logo.image?.size ?? CGSize(width: 3, height: 1)
        NSLayoutConstraint.activate([
            logo.heightAnchor.constraint(equalToConstant: 18),
            logo.widthAnchor.constraint(equalTo: logo.heightAnchor, multiplier: logoSize.width / max(logoSize.height, 1)),
        ])

        let content = UIStackView(arrangedSubviews: [label, logo])
        content.spacing = 6
        content.alignment = .center
        content.isUserInteractionEnabled = false
        content.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(content)
        NSLayoutConstraint.activate([
            content.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            content.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        ])
        return button
    }

    private func updateSaveButtonLogoAppearance() {
        saveButtonLogo?.overrideUserInterfaceStyle = traitCollection.userInterfaceStyle == .dark ? .light : .dark
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateSaveButtonLogoAppearance()
    }

    private func makeSavedItemsRow() -> UIView {
        let icon = UIImageView(image: UIImage(systemName: "person.text.rectangle"))
        icon.tintColor = .secondaryLabel
        icon.setContentHuggingPriority(.required, for: .horizontal)
        let label = UILabel()
        label.font = NetworkedIdentityUI.captionFont
        label.numberOfLines = 0
        label.text = networkedIdentity?.includesSelfie == true ? "ID document and selfie" : "ID document"
        let row = UIStackView(arrangedSubviews: [icon, label])
        row.spacing = 12
        row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = .init(top: 12, left: 12, bottom: 12, right: 12)
        row.layer.cornerRadius = 8
        row.layer.borderWidth = 1
        row.layer.borderColor = UIColor.separator.cgColor
        return row
    }

    @objc private func didTapWhatIsLink() {
        guard let url = URL(string: "https://link.com") else { return }
        openInSafariViewController(url: url)
    }

    @objc private func didTapSave() {
        networkedIdentity?.startSave(from: self) { [weak self] outcome in
            if outcome == .savePrepared {
                self?.renderSaveCard()
            }
        }
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SuccessViewController {
    fileprivate func didTapButton() {
        dismiss(animated: true, completion: nil)
    }
}
