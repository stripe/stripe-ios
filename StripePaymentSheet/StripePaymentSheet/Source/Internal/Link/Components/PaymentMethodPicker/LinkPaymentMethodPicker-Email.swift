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
            static let contentSpacing: CGFloat = 16
            static let insets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        }

        var accountEmail: String? {
            didSet {
                userEmailLabel.text = accountEmail
            }
        }

        private let emailLabel: UILabel = {
            let label = UILabel()
            label.text = String.Localized.email
            label.font = LinkUI.font(forTextStyle: .body)
            label.textColor = .linkSecondaryText
            label.adjustsFontForContentSizeCategory = true
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
            return label
        }()

        private let userEmailLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .body)
            label.textColor = .linkPrimaryText
            label.textAlignment = .center
            return label
        }()

        // Used to center-align the user email label.
        private lazy var userEmailContainerView: UIView = {
            let view = UIView()
            userEmailLabel.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(userEmailLabel)
            NSLayoutConstraint.activate([
                userEmailLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                userEmailLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                userEmailLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
                userEmailLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
                userEmailLabel.topAnchor.constraint(equalTo: view.topAnchor),
                userEmailLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
            return view
        }()

        private lazy var stackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                emailLabel,
                userEmailContainerView,
            ])

            stackView.axis = .horizontal
            stackView.spacing = Constants.contentSpacing
            stackView.distribution = .fill
            stackView.alignment = .center
            stackView.directionalLayoutMargins = Constants.insets
            stackView.isLayoutMarginsRelativeArrangement = true

            return stackView
        }()

        override init(frame: CGRect) {
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
    }
}
