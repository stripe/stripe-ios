//
//  LinkVerificationView-SandboxBannerView.swift
//  StripePaymentSheet
//
//  Created by Michael Liberatore on 11/12/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

extension LinkVerificationView {

    /// Displays Link verification instructions for sandbox mode.
    final class SandboxBannerView: UIView {
        private lazy var titleLabel: UILabel = {
            let titleLabel = UILabel()
            titleLabel.text = STPLocalizedString(
                "You’re in sandbox mode",
                "Title of a Link verification banner shown when using a sandbox or test mode."
            )

            titleLabel.font = LinkUI.font(forTextStyle: .detailEmphasized)
            titleLabel.textColor = .linkTextPrimary
            titleLabel.numberOfLines = 0
            titleLabel.adjustsFontForContentSizeCategory = true
            return titleLabel
        }()

        private lazy var detailLabel: UILabel = {
            let detailLabel = UILabel()
            detailLabel.text = STPLocalizedString(
                "No code will be sent. Enter 000000 to continue.",
                "Instructions for verifying a Link account in a sandbox or test mode. 000000 is the six-digit test verification code."
            )

            detailLabel.font = LinkUI.font(forTextStyle: .caption)
            detailLabel.textColor = .dynamic(light: .linkTextTertiary, dark: .linkTextSecondary)
            detailLabel.numberOfLines = 0
            detailLabel.adjustsFontForContentSizeCategory = true
            return detailLabel
        }()

        private lazy var iconContainerView: UIView = {
            let view = UIView()
            view.backgroundColor = .linkSurfaceSecondary
            view.layer.cornerRadius = 12
            return view
        }()

        private lazy var iconView: UIImageView = {
            let icon = UIImageView(image: Image.icon_link_warning_circle.makeImage(template: true))
            icon.tintColor = .linkIconPrimary
            icon.contentMode = .scaleAspectFit
            icon.translatesAutoresizingMaskIntoConstraints = false
            return icon
        }()

        init() {
            super.init(frame: .zero)
            setUpUI()
        }

        private func setUpUI() {
            let labels = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
            labels.axis = .vertical
            labels.spacing = LinkUI.tinyContentSpacing

            iconContainerView.addSubview(iconView)

            let content = UIStackView(arrangedSubviews: [iconContainerView, labels])
            content.axis = .horizontal
            content.alignment = .center
            content.spacing = LinkUI.contentSpacing
            content.isLayoutMarginsRelativeArrangement = true
            content.directionalLayoutMargins = .insets(amount: LinkUI.contentSpacing)
            addAndPinSubview(content)

            NSLayoutConstraint.activate([
                iconContainerView.widthAnchor.constraint(equalToConstant: 44),
                iconContainerView.heightAnchor.constraint(equalToConstant: 44),
                iconView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
                iconView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 20),
                iconView.heightAnchor.constraint(equalToConstant: 20),
            ])

            backgroundColor = .linkSurfacePrimary
            layer.cornerRadius = 24
            layer.borderWidth = 1
            layer.borderColor = UIColor.linkSurfaceTertiary.cgColor
            isAccessibilityElement = true
            accessibilityLabel = [titleLabel.text, detailLabel.text].compactMap { $0 }.joined(separator: ". ")
        }

        // MARK: - UIView

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        #if !os(visionOS)
        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            layer.borderColor = UIColor.linkSurfaceTertiary.cgColor
        }
        #endif
    }
}
