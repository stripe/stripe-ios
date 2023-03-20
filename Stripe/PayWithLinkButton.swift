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
        static let logoSize: CGSize = .init(width: 35, height: 16)
        static let margins: NSDirectionalEdgeInsets = .init(top: 7, leading: 16, bottom: 7, trailing: 10)
        static let emailContainerCornerRadius: CGFloat = 3
        static let emailContainerInsets: NSDirectionalEdgeInsets = .insets(amount: 6)
    }

    /// Link account of the current user.
    var linkAccount: PaymentSheetLinkAccountInfoProtocol? {
        didSet {
            emailLabel.text = linkAccount?.email
            updateUI()
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

    private lazy var logoView: UIImageView = Self.makeLogoView()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            Self.makeLogoView(),
            emailLabelContainer
        ])
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
        setupUI()
        applyStyle()
        updateUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        bounds.contains(point) ? self : nil
    }

}

// MARK: - UI

private extension PayWithLinkButton {

    static func makeLogoView() -> UIImageView {
        let logoView = UIImageView(image: Image.link_logo.makeImage(template: true))
        logoView.translatesAutoresizingMaskIntoConstraints = false
        logoView.contentMode = .scaleAspectFill

        NSLayoutConstraint.activate([
            logoView.widthAnchor.constraint(equalToConstant: Constants.logoSize.width),
            logoView.heightAnchor.constraint(equalToConstant: Constants.logoSize.height)
        ])

        return logoView
    }

    func setupUI() {
        directionalLayoutMargins = Constants.margins

        addSubview(logoView)
        addSubview(stackView)

        NSLayoutConstraint.activate([
            logoView.centerXAnchor.constraint(equalTo: centerXAnchor),
            logoView.centerYAnchor.constraint(equalTo: centerYAnchor),

            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        ])
    }

    func updateUI() {
        logoView.isHidden = hasValidLinkAccount
        stackView.isHidden = !hasValidLinkAccount
        updateAccessibilityContent()
    }

}

// MARK: - Styling

private extension PayWithLinkButton {

    func applyStyle() {
        layer.cornerRadius = cornerRadius

        let foregroundColor = self.foregroundColor(for: state)
        titleLabel.textColor = foregroundColor
        logoView.tintColor = foregroundColor
        stackView.tintColor = foregroundColor
        emailLabel.textColor = foregroundColor
        emailLabelContainer.backgroundColor = foregroundColor.withAlphaComponent(0.04)

        backgroundColor = backgroundColor(for: state)
    }

    func foregroundColor(for state: State) -> UIColor {
        switch state {
        case .highlighted:
            return UIColor.linkPrimaryButtonForeground.withAlphaComponent(0.8)
        default:
            return UIColor.linkPrimaryButtonForeground
        }
    }

    func backgroundColor(for state: State) -> UIColor {
        switch state {
        case .highlighted:
            return UIColor.linkBrand.darken(by: 0.2)
        case .disabled:
            return UIColor.linkBrand.withAlphaComponent(0.5)
        default:
            return UIColor.linkBrand
        }
    }

}

// MARK: - Accessibility

private extension PayWithLinkButton {

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

}
