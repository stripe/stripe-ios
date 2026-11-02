//
//  PayWithLinkViewController-NoFundingSourcesViewController.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 10/29/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeUICore

extension PayWithLinkViewController {

    /// Shown instead of the wallet when none of the consumer's payment details types are supported for this session.
    final class NoFundingSourcesViewController: BaseViewController {

        private enum Constants {
            static let iconContainerSize: CGFloat = 64
            static let iconSize: CGFloat = 24
            static let topPadding: CGFloat = 64
            static let buttonsTopPadding: CGFloat = 96
        }

        private lazy var iconView: UIView = {
            let imageView = UIImageView(image: Image.icon_link_warning_circle.makeImage(template: true))
            imageView.tintColor = .white
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false

            let containerView = UIView()
            containerView.backgroundColor = .linkIconCritical
            containerView.layer.cornerRadius = Constants.iconContainerSize / 2
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(imageView)

            NSLayoutConstraint.activate([
                containerView.widthAnchor.constraint(equalToConstant: Constants.iconContainerSize),
                containerView.heightAnchor.constraint(equalToConstant: Constants.iconContainerSize),
                imageView.widthAnchor.constraint(equalToConstant: Constants.iconSize),
                imageView.heightAnchor.constraint(equalToConstant: Constants.iconSize),
                imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            ])

            return containerView
        }()

        private lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .title)
            label.textColor = .linkTextPrimary
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            label.textAlignment = .center
            label.text = String.Localized.you_cant_pay_with_brand_here(brand: context.linkBrand)
            label.accessibilityLabel = context.linkBrand.accessibilityText(from: label.text ?? "")
            label.accessibilityTraits = .header
            return label
        }()

        private lazy var subtitleLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .body)
            label.textColor = .linkTextSecondary
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            label.textAlignment = .center
            label.text = String.Localized.none_of_the_payment_methods_in_your_brand_account_work_with_this_business(
                brand: context.linkBrand
            )
            label.accessibilityLabel = context.linkBrand.accessibilityText(from: label.text ?? "")
            return label
        }()

        private lazy var payAnotherWayButton: Button? = {
            guard context.canContinueWithoutLink else {
                return nil
            }
            let button = Button(configuration: primaryButtonConfiguration, title: context.secondaryButtonLabel)
            button.addTarget(self, action: #selector(payAnotherWayButtonTapped), for: .touchUpInside)
            return button
        }()

        private lazy var useAnotherAccountButton: Button = {
            // When the user can't leave Link, logging in to another account is the only action, so it becomes the primary button.
            let configuration = context.canContinueWithoutLink ? secondaryButtonConfiguration : primaryButtonConfiguration
            let button = Button(configuration: configuration, title: String.Localized.log_in_to_another_account)
            button.addTarget(self, action: #selector(useAnotherAccountButtonTapped), for: .touchUpInside)
            return button
        }()

        private var primaryButtonConfiguration: Button.Configuration {
            var configuration: Button.Configuration = .linkPrimary()
            if let contentOnPrimary = context.linkAppearance?.colors?.contentOnPrimary {
                configuration.foregroundColor = contentOnPrimary
            }
            if let primary = context.linkAppearance?.colors?.primary {
                configuration.backgroundColor = primary
                configuration.disabledBackgroundColor = primary
            }
            configuration.cornerRadius = context.linkAppearance?.primaryButton.cornerRadius ?? LinkUI.cornerRadius
            if let height = context.linkAppearance?.primaryButton.height {
                let verticalMargin = LinkUI.verticalMarginForPrimaryButton(withDesiredHeight: height)
                configuration.insets.top = verticalMargin
                configuration.insets.bottom = verticalMargin
            }
            return configuration
        }

        private var secondaryButtonConfiguration: Button.Configuration {
            var configuration: Button.Configuration = .linkPrimary()
            configuration.foregroundColor = .linkTextPrimary
            configuration.backgroundColor = .clear
            configuration.disabledBackgroundColor = .clear
            configuration.borderColor = .linkSecondaryButtonBorder
            configuration.borderWidth = 1
            configuration.colorTransforms.highlightedForeground = .setAlpha(amount: 0.5)
            return configuration
        }

        private var bottomInset: CGFloat {
            if #available(iOS 26.0, visionOS 26.0, *) {
                0
            } else {
                LinkUI.bottomInset
            }
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            let messageStackView = UIStackView(arrangedSubviews: [iconView, titleLabel, subtitleLabel])
            messageStackView.axis = .vertical
            messageStackView.alignment = .center
            messageStackView.spacing = LinkUI.tinyContentSpacing
            messageStackView.setCustomSpacing(LinkUI.largeContentSpacing, after: iconView)

            let buttonsStackView = UIStackView(arrangedSubviews: [payAnotherWayButton, useAnotherAccountButton].compactMap { $0 })
            buttonsStackView.axis = .vertical
            buttonsStackView.spacing = LinkUI.smallContentSpacing

            let containerView = UIStackView(arrangedSubviews: [messageStackView, buttonsStackView])
            containerView.axis = .vertical
            containerView.spacing = Constants.buttonsTopPadding
            containerView.isLayoutMarginsRelativeArrangement = true
            containerView.directionalLayoutMargins = preferredContentMargins
            containerView.directionalLayoutMargins.top = Constants.topPadding
            containerView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(containerView)

            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
                containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                containerView.bottomAnchor.constraint(
                    equalTo: contentView.safeAreaLayoutGuide.bottomAnchor,
                    constant: -bottomInset
                ),
            ])
        }

        @objc
        private func payAnotherWayButtonTapped() {
            coordinator?.cancel(shouldReturnToPaymentSheet: true)
        }

        @objc
        private func useAnotherAccountButtonTapped() {
            coordinator?.logout(cancel: false)
        }
    }
}
