//
//  ExpressCheckoutElementUIView.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

import PassKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

/// A UIKit view that displays wallet payment buttons (Apple Pay, Link).
@_spi(STP)
@_spi(ReactNativeSDK)
@MainActor
public final class ExpressCheckoutElementUIView: UIView {

    // MARK: - Private Properties

    private let configuration: Checkout.Configuration
    private let stackView = UIStackView()
    private var linkBrand: LinkBrand
    private weak var delegate: ExpressCheckoutElementDelegate?

    // MARK: - Init

    init(session: Checkout.Session, configuration: Checkout.Configuration, delegate: ExpressCheckoutElementDelegate) {
        self.configuration = configuration
        self.delegate = delegate
        self.linkBrand = session.elementsSession.linkBrand ?? .link
        super.init(frame: .zero)

        // TODO: Appearance
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        let buttons = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
        buttons.forEach { stackView.addArrangedSubview(makeButton(for: $0)) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal Methods

    func update(with session: Checkout.Session) {
        linkBrand = session.elementsSession.linkBrand ?? .link
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let buttons = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
        buttons.forEach { stackView.addArrangedSubview(makeButton(for: $0)) }
        invalidateIntrinsicContentSize()
    }

    // MARK: - Public Methods

    public override var intrinsicContentSize: CGSize {
        CGSize(
            width: UIView.noIntrinsicMetric,
            height: stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        )
    }

    // MARK: - Private Methods

    private func makeButton(for paymentMethod: ExpressCheckoutElement.PaymentMethod) -> UIView {
        switch paymentMethod {
        case .applePay:
            return makeApplePayButton()
        case .link:
            return makeLinkButton()
        }
    }

    private func makeApplePayButton() -> UIView {
        let buttonType = configuration.applePayConfiguration?.buttonType ?? .plain
        let button = PKPaymentButton(paymentButtonType: buttonType, paymentButtonStyle: .automatic)
        // TODO: Appearance
        button.cornerRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: #selector(handleApplePayTapped), for: .touchUpInside)
        return button
    }

    private func makeLinkButton() -> UIView {
        let button = PayWithLinkButton(brand: linkBrand)
        // TODO: Appearance
        button.cornerRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: #selector(handleLinkTapped), for: .touchUpInside)
        return button
    }

    @objc private func handleApplePayTapped() {
        confirm(.applePay)
    }

    @objc private func handleLinkTapped() {
        confirm(.link)
    }

    private func confirm(_ paymentMethod: ExpressCheckoutElement.PaymentMethod) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let presentingViewController = self.window?.rootViewController?.findTopMostPresentedViewController() else {
                let error = CheckoutError.unknown(debugDescription: "ExpressCheckoutElementUIView could not find a presenting view controller.")
                self.configuration.expressCheckoutElement.confirmHandler(.failed(error))
                return
            }
            guard let result = await self.delegate?.expressCheckoutElementShouldConfirm(
                paymentMethod,
                presentingViewController: presentingViewController
            ) else { return }
            self.configuration.expressCheckoutElement.confirmHandler(result)
        }
    }
}
