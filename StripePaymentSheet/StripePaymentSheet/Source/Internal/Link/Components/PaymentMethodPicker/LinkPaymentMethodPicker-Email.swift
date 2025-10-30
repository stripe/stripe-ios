//
//  LinkPaymentMethodPicker-Email.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 4/23/25.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

extension LinkPaymentMethodPicker {
    final class EmailView: UIView {
        enum Constants {
            static let buttonSize: CGSize = .init(width: 12, height: 16)
            static let contentSpacing: CGFloat = 16
            static let insets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 26)
        }

        private let linkConfiguration: LinkConfiguration?

        var accountEmail: String? {
            didSet {
                userEmailLabel.text = accountEmail
            }
        }

        private var menuButtonFrame: CGRect {
            let originalFrame = menuButton.convert(menuButton.bounds, to: self)

            let targetSize = CGSize(width: 44, height: 44)

            return CGRect(
                x: originalFrame.midX - (targetSize.width / 2),
                y: originalFrame.midY - (targetSize.height / 2),
                width: targetSize.width,
                height: targetSize.height
            )
        }

        private let emailLabel: UILabel = {
            let label = UILabel()
            label.text = String.Localized.email
            label.font = LinkUI.font(forTextStyle: .body)
            label.textColor = .linkTextTertiary
            label.adjustsFontForContentSizeCategory = true
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        private let userEmailLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .bodyEmphasized)
            label.textColor = .linkTextPrimary
            label.setContentHuggingPriority(.defaultLow, for: .horizontal)
            return label
        }()

        let menuButton: UIButton = {
            let button = UIButton(type: .system)
            button.setImage(Image.icon_menu.makeImage(), for: .normal)
            button.tintColor = .linkIconTertiary
            button.accessibilityLabel = String.Localized.show_menu
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: Constants.buttonSize.width),
                button.heightAnchor.constraint(equalToConstant: Constants.buttonSize.height),
            ])
            return button
        }()

        private lazy var stackView: UIStackView = {
            var arrangedSubviews: [UIView] = [emailLabel, userEmailLabel]

            if linkConfiguration?.allowLogout != false {
                arrangedSubviews.append(menuButton)
            }

            let stackView = UIStackView(arrangedSubviews: arrangedSubviews)

            stackView.axis = .horizontal
            stackView.spacing = Constants.contentSpacing
            stackView.distribution = .fill
            stackView.alignment = .center
            stackView.directionalLayoutMargins = Constants.insets
            stackView.isLayoutMarginsRelativeArrangement = true

            let widthAnchor = emailLabel.widthAnchor.constraint(equalToConstant: LinkPaymentMethodPicker.widthForHeaderLabels)

            // Keep this low priority so that it can break if the user email gets too big.
            widthAnchor.priority = .defaultLow

            widthAnchor.isActive = true

            return stackView
        }()

        init(linkConfiguration: LinkConfiguration? = nil) {
            self.linkConfiguration = linkConfiguration
            super.init(frame: .zero)
            addAndPinSubview(stackView)

            isAccessibilityElement = true
            accessibilityTraits = .staticText
            accessibilityLabel = userEmailLabel.text
            accessibilityHint = String.Localized.email
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            // Only check menu button hit test if logout is allowed.
            if linkConfiguration?.allowLogout != false && menuButtonFrame.contains(point) {
                return menuButton
            }

            return bounds.contains(point) ? self : nil
        }
    }
}
