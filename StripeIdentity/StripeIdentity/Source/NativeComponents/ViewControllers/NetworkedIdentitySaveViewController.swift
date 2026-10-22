//
//  NetworkedIdentitySaveViewController.swift
//  StripeIdentity
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

/// Networked Identity's offer to save this verification's ID to Link. It's shown once nothing else is missing, in
/// place of submitting, because a submitted verification can't record the save.
final class NetworkedIdentitySaveViewController: IdentityFlowViewController {
    // #TODO - Networked Identity: localize once the final mobile copy is approved.
    private enum Copy {
        static let title = "Verify faster next time"
        static let encrypted = "Link encrypts your saved information for your protection."
        static let saveWith = "Save with"
        static let saveWithLink = "Save with Link"
        static let finishWithoutSaving = "Finish without saving"

        static func subtitle(includesSelfie: Bool) -> String {
            includesSelfie ? "Save your ID and selfie with Link." : "Save your ID with Link."
        }

        static func reuse(includesSelfie: Bool) -> String {
            includesSelfie
                ? "Save your ID and selfie for the next time you need to verify."
                : "Save your ID for the next time you need to verify."
        }
    }

    private let networkedIdentity: NetworkedIdentityPresenter
    private let contentView = UIStackView()
    private let saveButton = Button(configuration: .networkedIdentitySave(), title: " ")
    private let saveButtonContent = UIStackView()
    private var isSubmitting = false {
        didSet {
            updateUI()
        }
    }

    /// Neither choice can be made while submitting or saving, including on Link's own screens, so finishing can't
    /// race a save that is still starting.
    private var isBusy: Bool {
        isSubmitting || networkedIdentity.coordinator.state.isInProgress
    }

    var flowViewModel: IdentityFlowView.ViewModel {
        .init(
            // The title is part of the content, since the header can't sit the design's 4 points above it.
            headerViewModel: nil,
            contentViewModel: .init(view: contentView, inset: .init(top: 48, leading: 24, bottom: 0, trailing: 24)),
            // Once the save is recorded, finishing would still save the ID.
            buttons: networkedIdentity.entry.offersSave ? [
                .init(
                    text: Copy.finishWithoutSaving,
                    state: isBusy ? .disabled : .enabled,
                    configuration: .networkedIdentityOutlined(),
                    didTap: { [weak self] in self?.finishWithoutSaving() }
                ),
            ] : [],
            // The flow view's buttons only take a title, so the save button with the Link logo goes above them.
            buttonTopAccessoryView: saveButton,
            buttonInsets: .init(top: 0, leading: 24, bottom: 8, trailing: 24),
            buttonSpacing: 16
        )
    }

    init(networkedIdentity: NetworkedIdentityPresenter, sheetController: VerificationSheetControllerProtocol) {
        self.networkedIdentity = networkedIdentity
        super.init(sheetController: sheetController, analyticsScreenName: .networkedIdentitySave)

        let title = UILabel()
        title.font = NetworkedIdentityUI.saveTitleFont
        title.textColor = NetworkedIdentityUI.saveTextColor
        title.textAlignment = .center
        title.numberOfLines = 0
        title.accessibilityTraits = .header
        title.setText(Copy.title, lineHeight: NetworkedIdentityUI.titleLineHeight)

        let subtitle = UILabel()
        subtitle.font = NetworkedIdentityUI.bodyFont
        subtitle.textColor = NetworkedIdentityUI.saveTextColor
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0
        subtitle.setText(
            Copy.subtitle(includesSelfie: networkedIdentity.includesSelfie),
            lineHeight: NetworkedIdentityUI.bodyLineHeight
        )

        let bullets = UIStackView(arrangedSubviews: [
            Self.makeBullet(icon: .linkId, text: Copy.reuse(includesSelfie: networkedIdentity.includesSelfie)),
            Self.makeBullet(icon: .linkLock, text: Copy.encrypted),
        ])
        bullets.axis = .vertical
        bullets.spacing = 16

        contentView.axis = .vertical
        contentView.addArrangedSubview(title)
        contentView.addArrangedSubview(subtitle)
        contentView.addArrangedSubview(bullets)
        contentView.setCustomSpacing(4, after: title)
        contentView.setCustomSpacing(24, after: subtitle)
        configureSaveButton()
        updateUI()
        // The presenter also calls this on each transition of a save attempt.
        networkedIdentity.onEntryChange = { [weak self] in self?.updateUI() }
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Private Helpers

extension NetworkedIdentitySaveViewController {
    fileprivate func updateUI() {
        saveButton.isEnabled = !isBusy
        // Dims like the button's own title would: the logo keeps its own colors.
        saveButtonContent.alpha = isBusy ? 0.5 : 1
        // `Button` resets its accessibility label to its title, which here only keeps the button's height.
        saveButton.accessibilityLabel = Copy.saveWithLink
        configure(backButtonTitle: nil, viewModel: flowViewModel)
    }

    /// "Save with [Link logo]", centered. `Button` pins icons to its edges, so the title and logo are laid over an
    /// empty title that keeps the button's height.
    fileprivate func configureSaveButton() {
        saveButton.addAction(UIAction { [weak self] _ in self?.save() }, for: .touchUpInside)
        saveButton.layer.shadowColor = UIColor.black.cgColor
        saveButton.layer.shadowOpacity = 0.04
        saveButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        // Core Animation's shadow radius is half the design's blur of 2.
        saveButton.layer.shadowRadius = 1

        let label = UILabel()
        label.font = NetworkedIdentityUI.bodyEmphasizedFont
        label.textColor = NetworkedIdentityUI.onLinkPrimaryColor
        label.adjustsFontForContentSizeCategory = true
        label.text = Copy.saveWith

        // Picks the logo's light or dark variant against the button's background: the design's mono logo on the
        // light theme's dark button, Link's logo on the dark theme's light button.
        let logo = DynamicImageView(
            dynamicImage: Image.linkSaveButtonLogo.makeImage(),
            pairedColor: NetworkedIdentityUI.linkPrimaryColor
        )
        logo.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            logo.widthAnchor.constraint(equalToConstant: 53),
            logo.heightAnchor.constraint(equalToConstant: 18),
        ])

        saveButtonContent.addArrangedSubview(label)
        saveButtonContent.addArrangedSubview(logo)
        saveButtonContent.spacing = 8
        saveButtonContent.alignment = .center
        saveButtonContent.isUserInteractionEnabled = false
        saveButtonContent.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addSubview(saveButtonContent)
        NSLayoutConstraint.activate([
            saveButtonContent.centerXAnchor.constraint(equalTo: saveButton.centerXAnchor),
            saveButtonContent.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor),
        ])
    }

    /// A reason to save: the design's icon in a circle, then its text.
    fileprivate static func makeBullet(icon: Image, text: String) -> UIView {
        let circle = UIImageView(image: icon.makeImage(template: true))
        circle.contentMode = .center
        circle.tintColor = NetworkedIdentityUI.linkPrimaryColor
        circle.backgroundColor = NetworkedIdentityUI.linkSurfaceSecondaryColor
        circle.layer.cornerRadius = 22
        NSLayoutConstraint.activate([
            circle.widthAnchor.constraint(equalToConstant: 44),
            circle.heightAnchor.constraint(equalToConstant: 44),
        ])

        let label = UILabel()
        label.font = NetworkedIdentityUI.bodyFont
        label.textColor = NetworkedIdentityUI.saveBulletTextColor
        label.numberOfLines = 0
        label.setText(text, lineHeight: NetworkedIdentityUI.bodyLineHeight)

        let row = UIStackView(arrangedSubviews: [circle, label])
        row.spacing = 16
        row.alignment = .center
        return row
    }

    fileprivate func save() {
        networkedIdentity.startSave(from: self) { [weak self] _ in
            // Once the save is recorded, Done or closing Link's sheet finishes the verification. After a failed or
            // cancelled save, the user can save again or finish without saving.
            guard let self, !self.networkedIdentity.entry.offersSave else { return }
            self.submit()
        }
    }

    /// Records the declined save, then submits. The submit doesn't wait on the decline succeeding.
    fileprivate func finishWithoutSaving() {
        isSubmitting = true
        Task { [weak self, networkedIdentity] in
            await networkedIdentity.declineSave()
            self?.submit()
        }
    }

    fileprivate func submit() {
        guard let sheetController else { return }
        isSubmitting = true
        sheetController.analyticsClient.startTrackingTimeToScreen(from: analyticsScreenName, sheetController: sheetController)
        sheetController.submitAndTransition { [weak self] in
            self?.isSubmitting = false
        }
    }
}
