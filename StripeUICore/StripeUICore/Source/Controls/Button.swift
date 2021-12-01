//
//  Button.swift
//  StripeUICore
//
//  Created by Ramon Torres on 11/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeCore

/// The custom button used throughout the Stripe SDK.
@_spi(STP) public class Button: UIControl {

    /// Configuration for the button appearance.
    ///
    /// Most of the time you should use one of the built-in configurations such as `.primary()` or `.secondary()`. For
    /// one-off customizations, you can modify the button's configuration once it has been instantiated, as follows:
    ///
    /// ```
    /// let myButton = Button(configuration: .secondary(), title: "Cancel")
    /// myButtton.configuration.cornerRadius = 4
    /// ```
    ///
    /// If you find yourself applying the same customizations multiple times, you should consider creating a reusable configuration. To create
    /// one, simply add an extension and implement a static method that returns the custom configuration:
    ///
    /// ```
    /// extension Button.Configuration {
    ///     static func panicButton() -> Self {
    ///         let configuration: Button.Configuration = .primary()
    ///         configuration.font = .boldSytemFont(ofSize: 32)
    ///         configuration.insets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    ///         configuration.cornerRadius = 4
    ///         configuration.backgroundColor = .systemRed
    ///         return configuration
    ///     }
    /// }
    /// ```
    ///
    /// Then use it the same way you would use any of the built-in configurations:
    ///
    /// ```
    /// let button = Button(configuration: .panicButton(), title: "Cancel")
    /// ```
    public struct Configuration {
        /// A special color value that resolves to the button's tint color at runtime.
        ///
        /// This is equivalent to `UIColor.tintColor` in iOS 15, except that it only works
        /// within the `Button` component and relies on identity comparison (`===`). Ideally we will
        /// backport `UIColor.tintColor`, but this is not currently possible due to its reliance on
        /// private APIs.
        public static let tintColor: UIColor = .init(red: 0, green: 0.5, blue: 1, alpha: 1)

        public var font: UIFont = .preferredFont(forTextStyle: .body, weight: .medium)
        public var cornerRadius: CGFloat = 10

        // Normal state
        public var foregroundColor: UIColor? = nil
        public var backgroundColor: UIColor? = nil

        // Disabled state
        public var disabledForegroundColor: UIColor? = nil
        public var disabledBackgroundColor: UIColor? = nil

        public var insets: NSDirectionalEdgeInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
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
            updateColors()
            updateAccessibilityContent()
        }
    }

    public override var isHighlighted: Bool {
        didSet {
            updateColors()
        }
    }

    public var configuration: Configuration {
        didSet {
            applyConfiguration()
        }
    }

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
            updateAccessibilityContent()
        }
    }

    public var attributedTitle: NSAttributedString? {
        get {
            return titleLabel.attributedText
        }
        set {
            titleLabel.attributedText = newValue
            updateAccessibilityContent()
        }
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
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

    private lazy var contentView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            leadingIconView,
            titleLabel,
            trailingIconView
        ])

        stackView.axis = .horizontal
        stackView.spacing = Self.minItemSpacing
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    /// Creates a button with the default configuration.
    public convenience init() {
        self.init(configuration: .primary())
    }

    /// Creates a button with the default configuration and the given title.
    /// - Parameter title: Button title.
    public convenience init(title: String) {
        self.init(configuration: .primary(), title: title)
    }

    /// Creates a button with the specified configuration and title.
    /// - Parameters:
    ///   - configuration: Button configuration.
    ///   - title: Button title.
    public convenience init(configuration: Configuration, title: String) {
        self.init(configuration: configuration)
        self.title = title
    }

    /// Creates a button with the specified configuration
    /// - Parameter configuration: Button configuration.
    public init(configuration: Configuration) {
        self.configuration = configuration
        super.init(frame: .zero)

        isAccessibilityElement = true
        accessibilityTraits = .button

        setup()
        applyConfiguration()
        updateAccessibilityContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addAndPinSubview(contentView)

        NSLayoutConstraint.activate([
            // Center label
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.minTitleLabelHeight)
        ])
    }

    public override func tintColorDidChange() {
        super.tintColorDidChange()
        updateColors()
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return bounds.contains(point) ? self : nil
    }
}

private extension Button {

    func applyConfiguration() {
        titleLabel.font = configuration.font
        layer.cornerRadius = configuration.cornerRadius
        contentView.directionalLayoutMargins = configuration.insets

        updateColors()
    }

    func updateColors() {
        let color = foregroundColor(for: state)

        titleLabel.textColor = color
        leadingIconView.tintColor = color
        trailingIconView.tintColor = color

        backgroundColor = backgroundColor(for: state)
    }

    func foregroundColor(for state: State) -> UIColor? {
        switch state {
        case .disabled:
            return resolveColor(
                configuration.disabledForegroundColor,
                configuration.foregroundColor
            )
        default:
            return resolveColor(configuration.foregroundColor)
        }
    }

    func backgroundColor(for state: State) -> UIColor? {
        switch state {
        case .highlighted:
            return resolveColor(configuration.backgroundColor)?.darken(by: 0.2)
        case .disabled:
            return resolveColor(
                configuration.disabledBackgroundColor,
                configuration.backgroundColor
            )
        default:
            return resolveColor(configuration.backgroundColor)
        }
    }

    func resolveColor(_ colors: UIColor?...) -> UIColor? {
        guard let color = colors.first(where: { $0 != nil }) else {
            return nil
        }

        return color === Configuration.tintColor ? tintColor : color
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

    func updateAccessibilityContent() {
        accessibilityLabel = title ?? attributedTitle?.string

        if isEnabled {
            accessibilityTraits.remove(.notEnabled)
        } else {
            accessibilityTraits.insert(.notEnabled)
        }
    }
}

public extension Button.Configuration {
    /// The default button configuration.
    static func primary() -> Self {
        return .init(
            foregroundColor: .white,
            backgroundColor: Self.tintColor,
            disabledBackgroundColor: CompatibleColor.systemGray4
        )
    }

    /// A less prominent button.
    static func secondary() -> Self {
        return .init(
            foregroundColor: Self.tintColor,
            backgroundColor: CompatibleColor.secondarySystemFill,
            disabledForegroundColor: .systemGray
        )
    }
}
