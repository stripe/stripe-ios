//
//  Button.swift
//  StripeUICore
//
//  Created by Ramon Torres on 11/7/21.
//

import UIKit
@_spi(STP) import StripeCore

/// The custom button used throughout the Stripe SDK.
@_spi(STP) public class Button: UIControl {
    /// Button style.
    public enum Style {
        /// The default button style.
        case primary
        /// A less prominent button.
        case secondary
    }

    /// Position of the icon.
    public enum IconPosition {
        /// Leading edge of the button.
        case leading
        /// Trailing edge of the button.
        case trailing
    }

    // Constants
    static let minTitleLabelHeight: CGFloat = 24
    static let minItemSpacing: CGFloat = 8

    public override var isEnabled: Bool {
        didSet {
            applyStyle()
        }
    }

    public override var isHighlighted: Bool {
        didSet {
            applyStyle()
        }
    }

    public var cornerRadius: CGFloat = 10 {
        didSet {
            applyStyle()
        }
    }

    public let style: Style

    public var icon: UIImage? {
        didSet {
            updateIcon()
        }
    }

    public var iconPosition: IconPosition = .leading {
        didSet {
            updateIcon()
        }
    }

    public var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
            accessibilityLabel = newValue
        }
    }

    public var font: UIFont {
        get {
            return titleLabel.font
        }
        set {
            titleLabel.font = newValue
        }
    }

    public var disabledColor: UIColor? {
        didSet {
            applyStyle()
        }
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let leadingIconView: UIImageView = {
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        return iconView
    }()

    // TODO(ramont): Remove reduntant icon view.
    private let trailingIconView: UIImageView = {
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        return iconView
    }()

    /// Creates a button with the default style and the given title.
    /// - Parameter title: The button title.
    public convenience init(title: String) {
        self.init(style: .primary, title: title)
    }

    /// Creates a button with the specified style and title.
    /// - Parameters:
    ///   - style: The button style.
    ///   - title: The button title.
    public init(style: Style, title: String) {
        self.style = style
        super.init(frame: .zero)
        self.title = title

        isAccessibilityElement = true
        accessibilityTraits = .button
        directionalLayoutMargins = .init(top: 10, leading: 10, bottom: 10, trailing: 10)

        setup()
        applyStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        let stackView = UIStackView(arrangedSubviews: [
            leadingIconView,
            titleLabel,
            trailingIconView
        ])

        stackView.axis = .horizontal
        stackView.spacing = Self.minItemSpacing
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

            // Center label
            titleLabel.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.minTitleLabelHeight)
        ])
    }

    public override func tintColorDidChange() {
        super.tintColorDidChange()
        applyStyle()
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return bounds.contains(point) ? self : nil
    }

}

private extension Button {

    func applyStyle() {
        layer.cornerRadius = cornerRadius

        let color = foregroundColor(for: state)

        titleLabel.textColor = color
        leadingIconView.tintColor = color
        trailingIconView.tintColor = color

        backgroundColor = backgroundColor(for: state)
    }

    func foregroundColor(for state: State) -> UIColor? {
        switch style {
        case .primary:
            return .white
        case .secondary:
            switch state {
            case .disabled:
                return disabledColor ?? .systemGray
            default:
                return tintColor
            }
        }
    }

    func backgroundColor(for state: State) -> UIColor {
        switch style {
        case .primary:
            switch state {
            case .highlighted:
                return tintColor.darken(by: 0.2)
            case .disabled:
                return disabledColor ?? CompatibleColor.systemGray4
            default:
                return tintColor
            }
        case .secondary:
            switch state {
            case .highlighted:
                return CompatibleColor.systemGray6.darken(by: 0.1)
            default:
                return CompatibleColor.systemGray6
            }
        }
    }

    func updateIcon() {
        switch iconPosition {
        case .leading:
            leadingIconView.image = icon
            trailingIconView.image = nil
        case .trailing:
            leadingIconView.image = nil
            trailingIconView.image = icon
        }
    }

}
