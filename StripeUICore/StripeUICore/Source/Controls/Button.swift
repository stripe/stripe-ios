//
//  Button.swift
//  StripeUICore
//
//  Created by Ramon Torres on 11/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import UIKit

/// The custom button used throughout the Stripe SDK.
/// For internal SDK use only
@objc(STP_Internal_Button)
@_spi(STP) public class Button: UIControl {
    struct Constants {
        // TODO(ramont): move to `Configuration`
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
        public var foregroundColor: UIColor?
        public var backgroundColor: UIColor?
        public var borderColor: UIColor?

        // Disabled state
        public var disabledForegroundColor: UIColor?
        public var disabledBackgroundColor: UIColor?
        public var disabledBorderColor: UIColor?

        // Color transforms
        public var colorTransforms: ColorTransformConfiguration = .init()

        /// Attributes to automatically apply to the title.
        public var titleAttributes: [NSAttributedString.Key: Any]?

        public var insets: NSDirectionalEdgeInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
    }

    public struct ColorTransformConfiguration {
        public var disabledForeground: ColorTransform?
        public var disabledBackground: ColorTransform?
        public var disabledBorder: ColorTransform?
        public var highlightedForeground: ColorTransform?
        public var highlightedBackground: ColorTransform?
        public var highlightedBorder: ColorTransform?
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

    public override var intrinsicContentSize: CGSize {
        var contentHeight: CGFloat {
            return max(
                iconView.intrinsicContentSize.height,
                titleLabel.intrinsicContentSize.height,
                Constants.minTitleLabelHeight
            )
        }

        let height = (
            directionalLayoutMargins.top +
            contentHeight +
            directionalLayoutMargins.bottom
        )

        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: height
        )
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
            configurationDidChange(oldValue)
        }
    }

    public var icon: UIImage? {
        didSet {
            iconView.image = icon

            let shouldHideIconView = icon == nil
            if iconView.isHidden != shouldHideIconView {
                iconView.isHidden = shouldHideIconView
                setNeedsUpdateConstraints()
            }
        }
    }

    public var iconPosition: IconPosition = .leading {
        didSet {
            if iconPosition != oldValue {
                setNeedsUpdateConstraints()
            }
        }
    }

    public var title: String? {
        didSet {
            updateTitle()
            updateAccessibilityContent()
        }
    }

    public var isLoading: Bool = false {
        didSet {
            if isLoading {
                iconView.alpha = 0
                titleLabel.alpha = 0
                isUserInteractionEnabled = false
                activityIndicator.startAnimating()
            } else {
                iconView.alpha = 1
                titleLabel.alpha = 1
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
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.isHidden = true
        return iconView
    }()

    private lazy var activityIndicator: ActivityIndicator = {
        let activityIndicator = ActivityIndicator()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()

    private var dynamicConstraints: [NSLayoutConstraint] = []

    /// Creates a button with the default configuration.
    public convenience init() {
        self.init(configuration: .primary())
    }

    /// Creates a button with the default configuration and the given title.
    /// - Parameter title: Button title.
    public convenience init(title: String) {
        self.init(configuration: .primary(), title: title)
    }

    /// Creates a button with the specified configuration.
    /// - Parameters:
    ///   - configuration: Button configuration.
    public convenience init(configuration: Configuration) {
        self.init(configuration: configuration, title: nil)
    }

    /// Creates a button with the specified configuration and title.
    /// - Parameters
    ///   - configuration: Button configuration.
    ///   - title: Button title.
    public init(configuration: Configuration, title: String?) {
        self.configuration = configuration
        self.title = title
        super.init(frame: .zero)

        isAccessibilityElement = true
        accessibilityTraits = .button

        setup()
        configurationDidChange(nil)
        updateAccessibilityContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(activityIndicator)
        addSubview(iconView)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            // Center label
            titleLabel.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor),

            // Center activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    public override func tintColorDidChange() {
        super.tintColorDidChange()
        updateColors()
    }

#if !canImport(CompositorServices)
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        invalidateIntrinsicContentSize()
        updateColors()
    }
#endif

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return bounds.contains(point) ? self : nil
    }
}

public extension Button {

    override func updateConstraints() {
        if !dynamicConstraints.isEmpty {
            NSLayoutConstraint.deactivate(dynamicConstraints)
            dynamicConstraints.removeAll()
        }

        let shouldShowIconView = icon != nil

        if shouldShowIconView {
            // Center icon vertically
            dynamicConstraints.append(
                iconView.centerYAnchor.constraint(equalTo: layoutMarginsGuide.centerYAnchor)
            )

            switch iconPosition {
            case .leading:
                dynamicConstraints.append(contentsOf: [
                    iconView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                    iconView.trailingAnchor.constraint(
                        lessThanOrEqualTo: titleLabel.leadingAnchor,
                        constant: Constants.minItemSpacing
                    ),
                    titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),
                ])
            case .trailing:
                dynamicConstraints.append(contentsOf: [
                    titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor),
                    titleLabel.trailingAnchor.constraint(
                        lessThanOrEqualTo: iconView.leadingAnchor,
                        constant: Constants.minItemSpacing
                    ),
                    iconView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                ])
            }
        } else {
            // Pin the leading and trailing edges of the label to the edges of the button.
            dynamicConstraints.append(contentsOf: [
                titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),
            ])
        }

        NSLayoutConstraint.activate(dynamicConstraints)

        // `super.updateConstraints()` must be called as the final step, as
        // suggested by the documentation.
        super.updateConstraints()
    }

}

private extension Button {

    func configurationDidChange(_ previousConfiguration: Configuration?) {
        titleLabel.font = configuration.font
        layer.cornerRadius = configuration.cornerRadius
        layer.borderWidth = configuration.borderWidth
        directionalLayoutMargins = configuration.insets

        updateColors()
        updateTitle()

        if configuration.shouldInvalidateIntrinsicContentSize(previousConfiguration) {
            invalidateIntrinsicContentSize()
        }
    }

    func updateColors() {
        let color = foregroundColor(for: state)

        titleLabel.textColor = color
        iconView.tintColor = color
        activityIndicator.tintColor = color

        backgroundColor = backgroundColor(for: state)
        layer.borderColor = borderColor(for: state)?.cgColor
    }

    func updateTitle() {
        if let title = title,
           let attributes = configuration.titleAttributes {
            titleLabel.attributedText = NSAttributedString(string: title, attributes: attributes)
        } else {
            titleLabel.text = title
        }
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

    func updateAccessibilityContent() {
        accessibilityLabel = title

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
            disabledBackgroundColor: .systemGray4,
            colorTransforms: .init(
                highlightedBackground: .darken(amount: 0.2)
            )
        )
    }

    /// A less prominent button.
    static func secondary() -> Self {
        return .init(
            foregroundColor: Self.tintColor,
            backgroundColor: .secondarySystemFill,
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
            // Match the insets of UIButton(style: .system)
            insets: .insets(top: 3, leading: 0, bottom: 3, trailing: 0)
        )
    }

}

// MARK: - Configuration diffing

extension Button.Configuration {

    func shouldInvalidateIntrinsicContentSize(_ previousConfiguration: Self?) -> Bool {
        return (
            self.font != previousConfiguration?.font ||
            self.insets != previousConfiguration?.insets
        )
    }

}
