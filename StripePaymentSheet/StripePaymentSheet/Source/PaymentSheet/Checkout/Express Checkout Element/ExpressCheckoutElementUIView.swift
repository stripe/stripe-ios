//
//  ExpressCheckoutElementUIView.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/21/26.
//

import Combine
import PassKit
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
import UIKit

// MARK: - ExpressCheckoutElementUIView

@_spi(STP)
extension Checkout {
    /// A UIKit view that renders express checkout wallet buttons (Apple Pay, Link) in a vertical stack.
    ///
    /// The view automatically observes the ``Checkout`` session and rebuilds buttons
    /// whenever available wallet types change. Place it directly in your view hierarchy:
    ///
    /// ```swift
    /// let expressView = Checkout.ExpressCheckoutElementUIView(checkout: checkout)
    /// expressView.onWalletTapped = { type in ... }
    /// stackView.addArrangedSubview(expressView)
    /// ```
    @MainActor
    public final class ExpressCheckoutElementUIView: UIView {

        // MARK: - Public Properties

        /// Called when the user taps a wallet button.
        public var onWalletTapped: ((ExpressButtonType) -> Void)?

        // MARK: - Private Properties

        private let checkout: Checkout

        private let stackView: UIStackView = {
            let sv = UIStackView()
            sv.axis = .vertical
            sv.spacing = 8
            sv.translatesAutoresizingMaskIntoConstraints = false
            return sv
        }()

        private var linkExpressButton: LinkExpressButton?
        private var accountObserver: LinkAccountContextObserver?
        private var sessionObserver: AnyCancellable?

        // MARK: - Init

        /// Creates an express checkout element view.
        /// - Parameter checkout: The ``Checkout`` instance managing the session.
        public init(checkout: Checkout) {
            self.checkout = checkout
            super.init(frame: .zero)
            autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(stackView)
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])

            handleSessionUpdate()

            accountObserver = LinkAccountContextObserver { [weak self] account in
                self?.updateLinkState(LinkButtonState.from(account))
            }

            sessionObserver = checkout.$session
                .dropFirst()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.handleSessionUpdate()
                }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Layout

        override public var intrinsicContentSize: CGSize {
            let height = stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            return CGSize(width: UIView.noIntrinsicMetric, height: height)
        }

        // MARK: - Private

        private enum Defaults {
            static let buttonHeight: CGFloat = 44
            static let cornerRadius: CGFloat = 6
            static let borderColor: UIColor = .systemGray3
        }

        private func handleSessionUpdate() {
            let session = checkout.session
            let buttons = ExpressButton.from(
                session.availableExpressButtonTypes,
                elementsSession: session.elementsSession,
                linkButtonState: LinkButtonState.from(LinkAccountContext.shared.account)
            )
            stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            linkExpressButton = nil
            configure(buttons: buttons)
        }

        private func updateLinkState(_ state: LinkButtonState) {
            linkExpressButton?.update(state: state)
        }

        private func configure(buttons: [ExpressButton]) {
            for button in buttons {
                switch button {
                case .applePay:
                    let applePayButton = makeApplePayButton(
                        height: Defaults.buttonHeight,
                        cornerRadius: Defaults.cornerRadius
                    )
                    applePayButton.addTarget(self, action: #selector(applePayTapped), for: .touchUpInside)
                    stackView.addArrangedSubview(applePayButton)
                case .link(let brand, let state):
                    let linkButton = LinkExpressButton(
                        brand: brand,
                        state: state,
                        height: Defaults.buttonHeight,
                        cornerRadius: Defaults.cornerRadius,
                        borderColor: Defaults.borderColor
                    )
                    linkButton.addTarget(self, action: #selector(linkTapped), for: .touchUpInside)
                    linkExpressButton = linkButton
                    stackView.addArrangedSubview(linkButton)
                }
            }
        }

        private func makeApplePayButton(height: CGFloat, cornerRadius: CGFloat) -> PKPaymentButton {
            let buttonType = checkout.configuration.applePayConfiguration?.buttonType ?? .plain
            let button = PKPaymentButton(paymentButtonType: buttonType, paymentButtonStyle: .automatic)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.cornerRadius = cornerRadius
            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: height),
            ])
            return button
        }

        @objc private func applePayTapped() {
            onWalletTapped?(.applePay)
        }

        @objc private func linkTapped() {
            onWalletTapped?(.link)
        }
    }
}

// MARK: - LinkExpressButton

/// A UIKit button styled to match the Link express checkout button.
@MainActor
private final class LinkExpressButton: UIControl {

    private enum Constants {
        static let logoHeight: CGFloat = 18
        static let contentSpacing: CGFloat = 10
        static let separatorWidth: CGFloat = 1
        static let horizontalPadding: CGFloat = 16
        static let fontSize: CGFloat = 15
    }

    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let separatorView: UIView = {
        let v = UIView()
        v.backgroundColor = .linkExpressCheckoutButtonDivider
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = Constants.separatorWidth / 2
        v.isHidden = true
        return v
    }()

    private let accountLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: Constants.fontSize, weight: .medium)
        l.textColor = .linkExpressCheckoutButtonForeground
        l.lineBreakMode = .byTruncatingTail
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = Constants.contentSpacing
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.isUserInteractionEnabled = false
        return sv
    }()

    init(brand: LinkBrand, state: LinkButtonState, height: CGFloat, cornerRadius: CGFloat, borderColor: UIColor) {
        super.init(frame: .zero)

        backgroundColor = .linkExpressCheckoutButtonBackground
        layer.cornerRadius = cornerRadius
        layer.borderWidth = 1
        layer.borderColor = borderColor.cgColor
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false

        logoImageView.image = brand.paymentSheetLogoImage

        contentStack.addArrangedSubview(logoImageView)
        contentStack.addArrangedSubview(separatorView)
        contentStack.addArrangedSubview(accountLabel)
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: height),
            logoImageView.heightAnchor.constraint(equalToConstant: Constants.logoHeight),
            separatorView.widthAnchor.constraint(equalToConstant: Constants.separatorWidth),
            separatorView.heightAnchor.constraint(equalToConstant: Constants.logoHeight),
            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: Constants.horizontalPadding),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -Constants.horizontalPadding),
        ])

        update(state: state)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(state: LinkButtonState) {
        switch state {
        case .signedOut:
            separatorView.isHidden = true
            accountLabel.isHidden = true
        case .signedIn(let email):
            accountLabel.text = email
            separatorView.isHidden = false
            accountLabel.isHidden = false
        case .withPaymentMethod(let last4):
            accountLabel.text = "••••\(last4)"
            separatorView.isHidden = false
            accountLabel.isHidden = false
        }
    }
}
