//
//  PayWithLinkButton.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 9/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/// A button for paying with Link.
/// For internal SDK use only
@objc(STP_Internal_PayWithLinkButton)
final class PayWithLinkButton: UIControl {

    struct Constants {
        /// A placeholder string for the Link logo.
        static let logoPlaceholder: String = "{Link}"

        static let defaultMargins: NSDirectionalEdgeInsets = .init(
            top: 10, leading: 10, bottom: 10, trailing: 10)

        static let loggedInMargins: NSDirectionalEdgeInsets = .init(
            top: 7, leading: 16, bottom: 7, trailing: 10)

        static let emailContainerCornerRadius: CGFloat = 3
        static let emailContainerInsets: NSDirectionalEdgeInsets = .init(
            top: 6, leading: 6, bottom: 6, trailing: 6)
    }

    /// Link account of the current user.
    var linkAccount: PaymentSheetLinkAccountInfoProtocol? {
        didSet {
            emailLabel.text = linkAccount?.email
            applyLayout()
            updateAccessibilityContent()
        }
    }

    var cornerRadius: CGFloat = ElementsUI.defaultCornerRadius {
        didSet {
            applyStyle()
        }
    }

    override var isHighlighted: Bool {
        didSet {
            applyStyle()
        }
    }

    override var isEnabled: Bool {
        didSet {
            applyStyle()
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 44)
    }

    private let titleBaseFont: UIFont = UIFont.systemFont(ofSize: 16, weight: .medium)

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
            .scaled(withTextStyle: .callout, maximumPointSize: 16)
        label.lineBreakMode = .byTruncatingMiddle
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var logoLabel: UILabel = {
        let logoLabel = UILabel()
        logoLabel.font = titleBaseFont
        logoLabel.attributedText = insertLogo(in: Constants.logoPlaceholder, withFont: logoLabel.font)
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        return logoLabel
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [logoLabel, emailLabelContainer])
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        return stackView
    }()

    private lazy var emailLabelContainer: UIView = {
        let container = UIView()
        container.layer.cornerRadius = Constants.emailContainerCornerRadius
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(emailLabel)
        container.addAndPinSubview(emailLabel, insets: Constants.emailContainerInsets)
        return container
    }()

    private var hasValidLinkAccount: Bool {
        return linkAccount?.isRegistered ?? false
    }

    init() {
        super.init(frame: .zero)

        isAccessibilityElement = true

        applyLayout()

        updateTitleLabel()
        updateAccessibilityContent()

        applyStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateTitleLabel()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        bounds.contains(point) ? self : nil
    }

    private func applyLayout() {
        if hasValidLinkAccount {
            directionalLayoutMargins = Constants.loggedInMargins

            titleLabel.removeFromSuperview()
            addSubview(stackView)
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
                stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
            ])
        } else {
            directionalLayoutMargins = Constants.defaultMargins

            stackView.removeFromSuperview()
            addSubview(titleLabel)
            NSLayoutConstraint.activate([
                titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                titleLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                titleLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
                titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),
            ])
        }
    }

}

private extension PayWithLinkButton {

    func applyStyle() {
        layer.cornerRadius = cornerRadius

        titleLabel.textColor = foregroundColor(for: state)
        logoLabel.textColor = foregroundColor(for: state)
        emailLabel.textColor = foregroundColor(for: state)
        emailLabelContainer.backgroundColor = foregroundColor(for: state)
            .withAlphaComponent(0.1)

        backgroundColor = backgroundColor(for: state)
    }

    func foregroundColor(for state: State) -> UIColor {
        switch state {
        case .highlighted:
            return .init(white: 1, alpha: 0.8)
        default:
            return .white
        }
    }

    func backgroundColor(for state: State) -> UIColor {
        switch state {
        case .highlighted:
            return .linkBrandDark
        case .disabled:
            return CompatibleColor.systemGray2
        default:
            return .linkBrand
        }
    }

}

private extension PayWithLinkButton {

    func updateTitleLabel() {
        titleLabel.font = titleBaseFont.scaled(
            withTextStyle: .callout,
            maximumPointSize: 20,
            compatibleWith: traitCollection
        )

        let string = String(
            format: String.Localized.pay_with_payment_method,
            Constants.logoPlaceholder
        )

        titleLabel.attributedText = insertLogo(in: string, withFont: titleLabel.font)
    }

    func updateAccessibilityContent() {
        if isEnabled {
            accessibilityTraits = [.button]
        } else {
            accessibilityTraits = [.button, .notEnabled]
        }

        accessibilityLabel = String(
            format: String.Localized.pay_with_payment_method,
            STPPaymentMethodType.link.displayName
        )

        if hasValidLinkAccount {
            accessibilityValue = linkAccount?.email
        } else {
            accessibilityValue = nil
        }
    }

    /// Inserts the Link logo image.
    ///
    /// This method finds and replaces the logo placeholder with an image. The inserted image
    /// is scaled and vertically aligned to look correctly with a given font.
    ///
    /// - Parameters:
    ///   - string: String containing the logo placeholder.
    ///   - font: The font that will be used for rendering the resulting string.
    /// - Returns: Formatted string.
    func insertLogo(in string: String, withFont font: UIFont) -> NSAttributedString {
        let result = NSMutableAttributedString(string: string)

        guard let range = result.string.range(of: Constants.logoPlaceholder) else {
            return result
        }

        let logo = Image.link_logo.makeImage(template: true)

        // Typesetting constants: These ensure that the logo looks correct from a
        // typesetting POV regardless of font size. The values are expressed normalized
        // relative to the logo height (1.0 == 100% logo height).
        let logoXHeight: CGFloat = 0.6914
        let logoDescender: CGFloat = -0.0185

        // Specifies how big the logo should be in relation to the font's x-height.
        let logoXHeightScale: CGFloat = 1.152

        let logoScale = (font.xHeight / (logo.size.height * logoXHeight)) * logoXHeightScale

        let logoBounds = CGRect(
            x: 0,
            y: logoDescender * logo.size.height * logoScale,
            width: logo.size.width * logoScale,
            height: logo.size.height * logoScale
        )

        let logoAttachment = NSTextAttachment()
        logoAttachment.image = logo
        logoAttachment.bounds = logoBounds

        let location = result.string.distance(from: result.string.startIndex, to: range.lowerBound)
        let length = result.string.distance(from: range.lowerBound, to: range.upperBound)

        result.replaceCharacters(
            in: NSRange(location: location, length: length),
            with: NSMutableAttributedString(attachment: logoAttachment)
        )

        return result
    }

}
