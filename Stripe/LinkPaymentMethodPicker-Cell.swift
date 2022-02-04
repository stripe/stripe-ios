//
//  LinkPaymentMethodPicker-Cell.swift
//  StripeiOS
//
//  Created by Ramon Torres on 10/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

protocol LinkPaymentMethodPickerCellDelegate: AnyObject {
    func savedPaymentPickerCellDidSelect(_ cell: LinkPaymentMethodPicker.Cell)
    func savedPaymentPickerCell(_ cell: LinkPaymentMethodPicker.Cell, didTapMenuButton button: UIButton)
}

extension LinkPaymentMethodPicker {

    final class Cell: UIControl {
        struct Constants {
            static let margins = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
            static let contentSpacing: CGFloat = 12
            static let menuSpacing: CGFloat = 8
            static let menuButtonSize: CGSize = .init(width: 24, height: 24)
            static let separatorHeight: CGFloat = 1
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
                update()
            }
        }

        weak var delegate: LinkPaymentMethodPickerCellDelegate?

        private let radioButton = RadioButton()

        private let contentView = CellContentView()

        private let activityIndicator = ActivityIndicator()

        private let defaultBadge = DefaultBadge()

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
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupUI() {
            let leftStack = UIStackView(arrangedSubviews: [radioButton, contentView])
            leftStack.spacing = Constants.contentSpacing

            let rightStack = UIStackView(arrangedSubviews: [defaultBadge, activityIndicator, menuButton])
            rightStack.spacing = Constants.menuSpacing
            rightStack.alignment = .center

            let stackView = UIStackView(arrangedSubviews: [leftStack, rightStack])
            stackView.spacing = Constants.contentSpacing
            stackView.distribution = .equalSpacing
            stackView.alignment = .center
            stackView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(stackView)

            addSubview(separator)

            NSLayoutConstraint.activate([
                // Menu button
                menuButton.widthAnchor.constraint(equalToConstant: Constants.menuButtonSize.width),
                menuButton.heightAnchor.constraint(equalToConstant: Constants.menuButtonSize.height),

                // Loader
                activityIndicator.widthAnchor.constraint(equalToConstant: Constants.menuButtonSize.width),
                activityIndicator.heightAnchor.constraint(equalToConstant: Constants.menuButtonSize.height),

                // Separator
                separator.heightAnchor.constraint(equalToConstant: Constants.separatorHeight),
                separator.bottomAnchor.constraint(equalTo: bottomAnchor),
                separator.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

                // Stack view
                stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
                stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
            ])
        }

        private func update() {
            contentView.paymentMethod = paymentMethod

            if let paymentMethod = paymentMethod {
                defaultBadge.isHidden = isLoading || !paymentMethod.isDefault
                menuButton.isHidden = isLoading

                if isLoading {
                    activityIndicator.startAnimating()
                } else {
                    activityIndicator.stopAnimating()
                }
            }

            updateAccessibilityContent()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            radioButton.isOn = isSelected
            backgroundColor = isHighlighted ? .linkControlHighlight : .clear
        }

        private func updateAccessibilityContent() {
            guard let paymentMethod = paymentMethod else {
                return
            }

            accessibilityLabel = paymentMethod.accessibilityDescription
            accessibilityCustomActions = [
                UIAccessibilityCustomAction(
                    // TODO(ramont): Localize
                    name: "Show menu",
                    target: self,
                    selector: #selector(onShowMenuAction(_:))
                )
            ]
        }

        @objc func onShowMenuAction(_ sender: UIAccessibilityCustomAction) {
            onMenuButtonTapped(menuButton)
        }

        @objc func onMenuButtonTapped(_ sender: UIButton) {
            delegate?.savedPaymentPickerCell(self, didTapMenuButton: sender)
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
