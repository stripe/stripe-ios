//
//  LinkShippingAddressPicker-Cell.swift
//  StripePaymentSheet
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

protocol LinkShippingAddressPickerCellDelegate: AnyObject {
    func shippingAddressPickerCellDidSelect(_ cell: LinkShippingAddressPicker.Cell)
    func shippingAddressPickerCell(_ cell: LinkShippingAddressPicker.Cell, didTapMenuButton button: UIButton)
    func shippingAddressPickerCellMenuActions(
        for cell: LinkShippingAddressPicker.Cell
    ) -> [PayWithLinkViewController.WalletViewController.Action]?
}

extension LinkShippingAddressPicker {

    /// Shows a shipping address's name on the first line and the address on the second.
    final class CellContentView: UIView {
        struct Constants {
            static let maxFontSize: CGFloat = 20
        }

        var shippingAddress: ShippingAddressesResponse.ShippingAddress? {
            didSet {
                let name = shippingAddress?.address.name
                nameLabel.text = name
                nameLabel.isHidden = name?.isEmpty ?? true
                addressLabel.text = shippingAddress?.formattedAddress
            }
        }

        private let nameLabel: UILabel = {
            let label = UILabel()
            label.adjustsFontForContentSizeCategory = true
            label.font = LinkUI.font(forTextStyle: .bodyEmphasized, maximumPointSize: Constants.maxFontSize)
            label.textColor = .linkTextPrimary
            return label
        }()

        private let addressLabel: UILabel = {
            let label = UILabel()
            label.adjustsFontForContentSizeCategory = true
            label.font = LinkUI.font(forTextStyle: .caption, maximumPointSize: Constants.maxFontSize)
            label.textColor = .linkTextTertiary
            label.numberOfLines = 0
            return label
        }()

        private lazy var stackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                nameLabel,
                addressLabel,
            ])
            stackView.axis = .vertical
            stackView.alignment = .leading
            stackView.spacing = 0
            stackView.translatesAutoresizingMaskIntoConstraints = false
            return stackView
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            addAndPinSubview(stackView)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    final class Cell: UIControl {
        typealias Constants = LinkPaymentMethodPicker.Cell.Constants

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

        var shippingAddress: ShippingAddressesResponse.ShippingAddress? {
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

        /// Whether to show the menu for removing the shipping address.
        var isRemovable: Bool = true {
            didSet {
                if isRemovable != oldValue {
                    update()
                }
            }
        }

        weak var delegate: LinkShippingAddressPickerCellDelegate?

        private let radioButton = LinkPaymentMethodPicker.RadioButton()

        private let contentView = CellContentView()

        private let activityIndicator = ActivityIndicator()

        private let defaultBadge = LinkBadgeView(
            type: .neutral,
            text: String.Localized.default_text
        )

        private let unavailableBadge = LinkBadgeView(type: .error, text: STPLocalizedString(
            "Unavailable for this purchase",
            "Label shown when a payment method cannot be used for the current transaction."
        ))

        private lazy var menuButton: UIButton = {
            let button = UIButton(type: .system)
            button.setImage(Image.icon_menu.makeImage(), for: .normal)
            button.tintColor = .linkIconTertiary
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
            separator.backgroundColor = .linkBorderDefault
            separator.translatesAutoresizingMaskIntoConstraints = false
            return separator
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)

            isAccessibilityElement = true
            directionalLayoutMargins = Constants.margins

            setupUI()

            let interaction = UIContextMenuInteraction(delegate: self)
            addInteraction(interaction)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupUI() {
            let rightStackView = UIStackView(arrangedSubviews: [defaultBadge, activityIndicator, menuButton])
            rightStackView.spacing = LinkUI.smallContentSpacing
            rightStackView.alignment = .center
            rightStackView.setContentHuggingPriority(.required, for: .horizontal)
            rightStackView.setContentCompressionResistancePriority(.required, for: .horizontal)

            let stackView = UIStackView(arrangedSubviews: [contentView, rightStackView])
            stackView.spacing = Constants.contentSpacing
            stackView.alignment = .center

            let container = UIStackView(arrangedSubviews: [stackView, unavailableBadge])
            container.axis = .vertical
            container.spacing = Constants.contentSpacing
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

            if LinkUI.useLiquidGlass {
                NSLayoutConstraint.activate([
                    heightAnchor.constraint(greaterThanOrEqualToConstant: LinkUI.minimumItemHeightForLiquidGlass),
                ])
            }
        }

        private func update() {
            contentView.shippingAddress = shippingAddress
            updateAccessibilityContent()

            guard let shippingAddress else {
                return
            }

            defaultBadge.isHidden = isLoading || !(shippingAddress.isDefault ?? false)
            menuButton.isHidden = isLoading || !isRemovable
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
            backgroundColor = isHighlighted ? .linkSurfaceTertiary : .clear
        }

        private func updateAccessibilityContent() {
            guard let shippingAddress else {
                return
            }

            accessibilityIdentifier = "Stripe.Link.ShippingAddressPickerCell"
            accessibilityLabel = shippingAddress.accessibilityDescription
            accessibilityCustomActions = isRemovable ? [
                UIAccessibilityCustomAction(
                    name: String.Localized.show_menu,
                    target: self,
                    selector: #selector(onShowMenuAction)
                ),
            ] : nil
        }

        @objc func onShowMenuAction() {
            onMenuButtonTapped(menuButton)
        }

        @objc func onMenuButtonTapped(_ sender: UIButton) {
            delegate?.shippingAddressPickerCell(self, didTapMenuButton: sender)
        }

        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            if !menuButton.isHidden && menuButtonFrame.contains(point) {
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
                delegate?.shippingAddressPickerCellDidSelect(self)
            }
        }

    }

}

extension LinkShippingAddressPicker.Cell {
    override func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard isRemovable,
              let actions = delegate?.shippingAddressPickerCellMenuActions(for: self) else { return nil }

        let actionsProvider: UIContextMenuActionProvider = { _ in
            let menuActions = actions.map { action in
                UIAction(
                    title: action.title,
                    attributes: action.contextMenuAttribute,
                    handler: { _ in action.action() }
                )
            }
            return UIMenu(children: menuActions)
        }

        return UIContextMenuConfiguration(actionProvider: actionsProvider)
    }
}

extension ShippingAddressesResponse.ShippingAddress {
    var accessibilityDescription: String {
        [address.name, formattedAddress]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}
