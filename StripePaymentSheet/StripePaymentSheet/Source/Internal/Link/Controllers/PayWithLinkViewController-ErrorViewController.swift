//
//  PayWithLinkViewController-ErrorViewController.swift
//  StripePaymentSheet
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension PayWithLinkViewController {

    final class ErrorViewController: BaseViewController {
        private struct Constants {
            static let iconSize: CGFloat = 44
            static let extraLargeContentSpacing: CGFloat = LinkUI.extraLargeContentSpacing
            static let contentSpacing: CGFloat = LinkUI.contentSpacing
            static let smallContentSpacing: CGFloat = LinkUI.smallContentSpacing
        }

        private lazy var iconView: UIImageView = {
            let imageView = UIImageView(image: Image.icon_link_warning_circle.makeImage(template: true))
            imageView.tintColor = .linkTextCritical
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: Constants.iconSize),
                imageView.heightAnchor.constraint(equalToConstant: Constants.iconSize),
            ])
            return imageView
        }()

        private lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.text = String.Localized.something_went_wrong
            label.textColor = .linkTextPrimary
            label.font = LinkUI.font(forTextStyle: .bodyEmphasized)
            label.textAlignment = .center
            label.numberOfLines = 0
            return label
        }()

        private lazy var subtitleLabel: UILabel = {
            let label = UILabel()
            label.text = String.Localized.no_compatible_payment_methods
            label.textColor = .linkTextSecondary
            label.font = LinkUI.font(forTextStyle: .detail)
            label.textAlignment = .center
            label.numberOfLines = 0
            return label
        }()

        private lazy var useAnotherAccountButton: Button = {
            let button = Button(
                configuration: .linkPrimary(),
                title: String.Localized.use_another_account
            )
            button.addTarget(self, action: #selector(useAnotherAccountTapped), for: .touchUpInside)
            return button
        }()

        private lazy var payAnotherWayButton: Button = {
            let button = Button(
                configuration: .linkPlain(),
                title: context.secondaryButtonLabel
            )
            button.addTarget(self, action: #selector(payAnotherWayTapped), for: .touchUpInside)
            return button
        }()

        private var bottomInset: CGFloat {
            if #available(iOS 26.0, visionOS 26.0, *) {
                0
            } else {
                LinkUI.bottomInset
            }
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
        }

        private func setupUI() {
            let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
            textStack.axis = .vertical
            textStack.spacing = Constants.smallContentSpacing
            textStack.alignment = .center

            let centeredContentStack = UIStackView(arrangedSubviews: [iconView, textStack])
            centeredContentStack.axis = .vertical
            centeredContentStack.spacing = Constants.contentSpacing
            centeredContentStack.alignment = .center

            var buttonViews: [UIView] = [useAnotherAccountButton]
            if context.canContinueWithoutLink {
                buttonViews.append(payAnotherWayButton)
            }

            let buttonStack = UIStackView(arrangedSubviews: buttonViews)
            buttonStack.axis = .vertical
            buttonStack.spacing = Constants.contentSpacing

            let containerStack = UIStackView(
                arrangedSubviews: [centeredContentStack, buttonStack]
            )
            containerStack.axis = .vertical
            containerStack.spacing = Constants.extraLargeContentSpacing
            containerStack.isLayoutMarginsRelativeArrangement = true
            containerStack.directionalLayoutMargins = preferredContentMargins

            contentView.addAndPinSubview(containerStack, insets: .insets(bottom: bottomInset))
        }

        @objc private func useAnotherAccountTapped() {
            coordinator?.logout(cancel: false)
        }

        @objc private func payAnotherWayTapped() {
            coordinator?.cancel(shouldReturnToPaymentSheet: true)
        }
    }
}
