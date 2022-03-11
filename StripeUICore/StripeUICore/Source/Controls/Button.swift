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
/// For internal SDK use only
@objc(STP_Internal_Button)
@_spi(STP) public class Button: UIControl {
    struct Constants {
        static let minTitleLabelHeight: CGFloat = 24
        static let minItemSpacing: CGFloat = 8
    }

    /// Configuration for the button appearance.
    ///
    /// Most of the time you should use one of the built-in configurations such as `.primary()` or `.secondary()`. For
    /// one-off customizations, you can modify the button's configuration once it has been instantiated, as follows:
    ///
    /// ```
    /// let myButton = Button(configuration: .secondary(), title: "Cancel")
    /// myButton.configuration.cornerRadius = 4
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

        public var borderWidth: CGFloat = 0

        // Normal state
        public var foregroundColor: UIColor? = nil
        public var backgroundColor: UIColor? = nil
        public var borderColor: UIColor? = nil

        // Disabled state
        public var disabledForegroundColor: UIColor? = nil
        public var disabledBackgroundColor: UIColor? = nil
        public var disabledBorderColor: UIColor? = nil

        // Color transforms
        public var colorTransforms: ColorTransformConfiguration = .init()

        public var insets: NSDirectionalEdgeInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
    }

    public struct ColorTransformConfiguration {
        public var disabledForeground: ColorTransform? = nil
        public var disabledBackground: ColorTransform? = nil
        public var disabledBorder: ColorTransform? = nil
        public var highlightedForeground: ColorTransform? = nil
        public var highlightedBackground: ColorTransform? = nil
        public var highlightedBorder: ColorTransform? = nil
    }

    public enum ColorTransform {
        case darken(amount: CGFloat)
        case lighten(amount: CGFloat)
        case setAlpha(amount: CGFloat)
    }

    /// Position of the icon.
    public enum IconPosition {
        /// Leading edge of the button.
        case leading
        /// Trailing edge of the button.
        case trailing
    }

    struct CustomStates {
        static let loading = State(rawValue: 1 << 16)
    }

    public override var state: UIControl.State {
        var state = super.state

        if isLoading {
            state.insert(CustomStates.loading)
        }

        return state
    }

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

    public var isLoading: Bool = false {
        didSet {
            if isLoading {
                contentView.alpha = 0
                isUserInteractionEnabled = false
                activityIndicator.startAnimating()
            } else {
                contentView.alpha = 1
                isUserInteractionEnabled = true
                activityIndicator.stopAnimating()
            }
        }
    }

    /// Whether or not the button should automatically update its font when the device's content size category changes.
    public var adjustsFontForContentSizeCategory: Bool {
        get {
            return titleLabel.adjustsFontForContentSizeCategory
        }
        set {
            titleLabel.adjustsFontForContentSizeCategory = newValue
        }
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let leadingIconView: UIImageView = UIImageView()

    // TODO(ramont): Remove redundant icon view.
    private let trailingIconView: UIImageView = UIImageView()

    private lazy var contentView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            leadingIconView,
            titleLabel,
            trailingIconView
        ])

        stackView.axis = .horizontal
        stackView.spacing = Constants.minItemSpacing
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var activityIndicator: ActivityIndicator = {
        let activityIndicator = ActivityIndicator()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
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
        addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            // Center label
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.minTitleLabelHeight),

            // Center activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    public override func tintColorDidChange() {
        super.tintColorDidChange()
        updateColors()
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
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
        layer.borderWidth = configuration.borderWidth
        contentView.directionalLayoutMargins = configuration.insets

        updateColors()
    }

    func updateColors() {
        let color = foregroundColor(for: state)

        titleLabel.textColor = color
        leadingIconView.tintColor = color
        trailingIconView.tintColor = color
        activityIndicator.tintColor = color

        backgroundColor = backgroundColor(for: state)
        layer.borderColor = borderColor(for: state)?.cgColor
    }

    func foregroundColor(for state: State) -> UIColor? {
        switch state {
        case .disabled:
            return resolveColor(
                baseColor: configuration.foregroundColor,
                preferredColor: configuration.disabledForegroundColor,
                transform: configuration.colorTransforms.disabledForeground
            )
        case .highlighted:
            return resolveColor(
                baseColor: configuration.foregroundColor,
                transform: configuration.colorTransforms.highlightedForeground
            )
        default:
            return resolveColor(baseColor: configuration.foregroundColor)
        }
    }

    func backgroundColor(for state: State) -> UIColor? {
        switch state {
        case .disabled:
            return resolveColor(
                baseColor: configuration.backgroundColor,
                preferredColor: configuration.disabledBackgroundColor,
                transform: configuration.colorTransforms.disabledBackground
            )
        case .highlighted:
            return resolveColor(
                baseColor: configuration.backgroundColor,
                transform: configuration.colorTransforms.highlightedBackground
            )
        default:
            return resolveColor(baseColor: configuration.backgroundColor)
        }
    }

    func borderColor(for state: State) -> UIColor? {
        switch state {
        case .disabled:
            return resolveColor(
                baseColor: configuration.borderColor,
                preferredColor: configuration.disabledBorderColor,
                transform: configuration.colorTransforms.disabledBorder
            )
        case .highlighted:
            return resolveColor(
                baseColor: configuration.borderColor,
                transform: configuration.colorTransforms.highlightedBorder
            )
        default:
            return resolveColor(baseColor: configuration.borderColor)
        }
    }

    /// Determines the best color to use given a base color, a preferred color, and a color transform.
    ///
    /// If a preferred colors is provided, this method will always return the preferred color. Otherwise, the
    /// method will return the base color with an optional color transformation applied to it.
    ///
    /// - Parameters:
    ///   - baseColor: Base (untransformed) color.
    ///   - preferredColor: Preferred color.
    ///   - transform: Optional color transform to apply to `baseColor`.
    /// - Returns: Color to use.
    func resolveColor(
        baseColor: UIColor?,
        preferredColor: UIColor? = nil,
        transform: ColorTransform? = nil
    ) -> UIColor? {
        let resolveToTintColor: (UIColor?) -> UIColor? = { color in
            return color === Configuration.tintColor ? self.tintColor : color
        }

        if let preferredColor = preferredColor {
            return resolveToTintColor(preferredColor)
        }

        let color = resolveToTintColor(baseColor)

        switch transform {
        case .setAlpha(let amount):
            return color?.withAlphaComponent(amount)
        case .darken(let amount):
            return color?.darken(by: amount)
        case .lighten(let amount):
            return color?.lighten(by: amount)
        case .none:
            return color
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
            disabledBackgroundColor: CompatibleColor.systemGray4,
            colorTransforms: .init(
                highlightedBackground: .darken(amount: 0.2)
            )
        )
    }

    /// A less prominent button.
    static func secondary() -> Self {
        return .init(
            foregroundColor: Self.tintColor,
            backgroundColor: CompatibleColor.secondarySystemFill,
            disabledForegroundColor: .systemGray,
            colorTransforms: .init(
                highlightedBackground: .darken(amount: 0.2)
            )
        )
    }

    /// A plain button.
    static func plain() -> Self {
        return .init(
            font: .preferredFont(forTextStyle: .body, weight: .regular),
            foregroundColor: Self.tintColor,
            backgroundColor: .clear,
            // Match the custom color of UIButton(style: .system)
            disabledForegroundColor: .dynamic(
                light: UIColor(white: 0.484669, alpha: 0.35),
                dark: UIColor(white: 0.484669, alpha: 0.45)
            ),
            colorTransforms: .init(
                highlightedForeground: .setAlpha(amount: 0.5)
            ),
            insets: .zero
        )
    }

}
