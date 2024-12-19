//
//  LinkPaymentMethodPicker-Cell.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 10/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol LinkPaymentMethodPickerCellDelegate: AnyObject {
    func savedPaymentPickerCellDidSelect(_ cell: LinkPaymentMethodPicker.Cell)
    func savedPaymentPickerCell(_ cell: LinkPaymentMethodPicker.Cell, didTapMenuButton button: UIButton)
}

extension LinkPaymentMethodPicker {

    final class Cell: UIControl {
        struct Constants {
            static let margins = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
            static let contentSpacing: CGFloat = 12
            static let contentIndentation: CGFloat = 34
            static let menuSpacing: CGFloat = 8
            static let menuButtonSize: CGSize = .init(width: 24, height: 24)
            static let separatorHeight: CGFloat = 1
            static let iconViewSize: CGSize = .init(width: 14, height: 20)
            static let disabledContentAlpha: CGFloat = 0.5
        }

        override var isHighlighted: Bool {
            didSet {
                setNeedsLayout()
            }
        }

        override var isSelected: Bool {
            didSet {
                setNeedsLayout()
            }
        }

        var paymentMethod: ConsumerPaymentDetails? {
            didSet {
                update()
            }
        }

        var isLoading: Bool = false {
            didSet {
                if isLoading != oldValue {
                    update()
                }
            }
        }

        var isSupported: Bool = true {
            didSet {
                if isSupported != oldValue {
                    update()
                }
            }
        }

        weak var delegate: LinkPaymentMethodPickerCellDelegate?

        private let radioButton = RadioButton()

        private let contentView = CellContentView()

        private let activityIndicator = ActivityIndicator()

        private let defaultBadge = LinkBadgeView(
            type: .neutral,
            text: String.Localized.default_text
        )

        private let alertIconView: UIImageView = {
            let iconView = UIImageView()
            iconView.contentMode = .scaleAspectFit
            iconView.image = Image.icon_link_error.makeImage(template: true)
            iconView.tintColor = .linkDangerForeground
            return iconView
        }()

        private let unavailableBadge = LinkBadgeView(type: .error, text: STPLocalizedString(
            "Unavailable for this purchase",
            "Label shown when a payment method cannot be used for the current transaction."
        ))

        private lazy var menuButton: UIButton = {
            let button = UIButton(type: .system)
            button.setImage(Image.icon_menu.makeImage(), for: .normal)
            button.addTarget(self, action: #selector(onMenuButtonTapped(_:)), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()

        /// The menu button frame for hit-testing purposes.
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

        private let separator: UIView = {
            let separator = UIView()
            separator.backgroundColor = .linkControlBorder
            separator.translatesAutoresizingMaskIntoConstraints = false
            return separator
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)

            isAccessibilityElement = true
            directionalLayoutMargins = Constants.margins

            setupUI()
            addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(onCellLongPressed)))
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupUI() {
            let rightStackView = UIStackView(arrangedSubviews: [defaultBadge, alertIconView, activityIndicator, menuButton])
            rightStackView.spacing = LinkUI.smallContentSpacing
            rightStackView.distribution = .equalSpacing
            rightStackView.alignment = .center

            let stackView = UIStackView(arrangedSubviews: [contentView, rightStackView])
            stackView.spacing = Constants.contentSpacing
            stackView.distribution = .equalSpacing
            stackView.alignment = .center

            let container = UIStackView(arrangedSubviews: [stackView, unavailableBadge])
            container.axis = .vertical
            container.spacing = Constants.contentSpacing
            container.distribution = .equalSpacing
            container.alignment = .leading
            container.translatesAutoresizingMaskIntoConstraints = false
            addSubview(container)

            radioButton.translatesAutoresizingMaskIntoConstraints = false
            addSubview(radioButton)

            addSubview(separator)

            NSLayoutConstraint.activate([
                // Radio button
                radioButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                radioButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

                // Menu button
                menuButton.widthAnchor.constraint(equalToConstant: Constants.menuButtonSize.width),
                menuButton.heightAnchor.constraint(equalToConstant: Constants.menuButtonSize.height),

                // Loader
                activityIndicator.widthAnchor.constraint(equalToConstant: Constants.menuButtonSize.width),
                activityIndicator.heightAnchor.constraint(equalToConstant: Constants.menuButtonSize.height),

                // Icon
                alertIconView.widthAnchor.constraint(equalToConstant: Constants.iconViewSize.width),
                alertIconView.heightAnchor.constraint(equalToConstant: Constants.iconViewSize.height),

                // Container
                container.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                container.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
                container.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: Constants.contentIndentation),
                container.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                // Make stackView fill the container
                stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor),

                // Separator
                separator.heightAnchor.constraint(equalToConstant: Constants.separatorHeight),
                separator.bottomAnchor.constraint(equalTo: bottomAnchor),
                separator.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            ])
        }

        private func update() {
            contentView.paymentMethod = paymentMethod
            updateAccessibilityContent()

            guard let paymentMethod else {
                return
            }

            var hasExpired: Bool {
                switch paymentMethod.details {
                case .card(let card):
                    return card.hasExpired
                case .bankAccount, .unparsable:
                    return false
                }
            }

            defaultBadge.isHidden = isLoading || !paymentMethod.isDefault
            alertIconView.isHidden = isLoading || !hasExpired
            menuButton.isHidden = isLoading
            contentView.alpha = isSupported ? 1 : Constants.disabledContentAlpha
            unavailableBadge.isHidden = isSupported

            if isLoading {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            radioButton.isOn = isSelected
            backgroundColor = isHighlighted ? .linkControlHighlight : .clear
        }

        private func updateAccessibilityContent() {
            guard let paymentMethod else {
                return
            }

            accessibilityIdentifier = "Stripe.Link.PaymentMethodPickerCell"
            accessibilityLabel = paymentMethod.accessibilityDescription
            accessibilityCustomActions = [
                UIAccessibilityCustomAction(
                    name: String.Localized.show_menu,
                    target: self,
                    selector: #selector(onShowMenuAction(_:))
                ),
            ]
        }

        @objc func onShowMenuAction(_ sender: UIAccessibilityCustomAction) {
            onMenuButtonTapped(menuButton)
        }

        @objc func onMenuButtonTapped(_ sender: UIButton) {
            delegate?.savedPaymentPickerCell(self, didTapMenuButton: sender)
        }

        @objc func onCellLongPressed() {
            delegate?.savedPaymentPickerCell(self, didTapMenuButton: menuButton)
        }

        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            if menuButtonFrame.contains(point) {
                return menuButton
            }

            return bounds.contains(point) ? self : nil
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesEnded(touches, with: event)

            guard let touchLocation = touches.first?.location(in: self) else {
                return
            }

            if bounds.contains(touchLocation) {
                delegate?.savedPaymentPickerCellDidSelect(self)
            }
        }

    }

}
