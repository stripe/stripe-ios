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

    private let configuration: CheckoutController.Configuration
    private let stackView = UIStackView()
    private var linkBrand: LinkBrand
    private weak var delegate: ExpressCheckoutElementDelegate?

    // MARK: - Init

    init(session: CheckoutController.Session, configuration: CheckoutController.Configuration, delegate: ExpressCheckoutElementDelegate) {
        self.configuration = configuration
        self.delegate = delegate
        self.linkBrand = session.elementsSession.linkBrand ?? .link
        super.init(frame: .zero)

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
        layoutButtons(buttons)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal Methods

    func update(with session: CheckoutController.Session) {
        linkBrand = session.elementsSession.linkBrand ?? .link
        let buttons = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
        layoutButtons(buttons)
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

    /// Arranges `buttons` into rows of `appearance.buttonLayout.maxColumns`, capped at `appearance.buttonLayout.maxRows`.
    private func layoutButtons(_ buttons: [ExpressCheckoutElement.PaymentMethod]) {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let layout = configuration.expressCheckoutElement.appearance.buttonLayout
        let columns: Int
        if let maxColumns = layout.maxColumns {
            columns = max(maxColumns, 1)
        } else if let maxRows = layout.maxRows, maxRows > 0 {
            // No explicit column limit, so spread buttons across the available rows rather than dropping any.
            columns = max(Int((Double(buttons.count) / Double(maxRows)).rounded(.up)), 1)
        } else {
            columns = 1
        }
        var rows = stride(from: 0, to: buttons.count, by: columns).map {
            Array(buttons[$0..<min($0 + columns, buttons.count)])
        }
        if let maxRows = layout.maxRows {
            rows = Array(rows.prefix(max(maxRows, 0)))
        }

        for row in rows {
            if row.count == 1, let method = row.first {
                stackView.addArrangedSubview(makeButton(for: method))
            } else {
                let rowStackView = UIStackView(arrangedSubviews: row.map { makeButton(for: $0) })
                rowStackView.axis = .horizontal
                rowStackView.spacing = 8
                rowStackView.distribution = .fillEqually
                stackView.addArrangedSubview(rowStackView)
            }
        }
    }

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
        let button = PKPaymentButton(paymentButtonType: buttonType, paymentButtonStyle: applePayButtonStyle)
        button.cornerRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: #selector(handleApplePayTapped), for: .touchUpInside)
        return button
    }

    private func makeLinkButton() -> UIView {
        let button = PayWithLinkButton(brand: linkBrand)
        button.cornerRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: #selector(handleLinkTapped), for: .touchUpInside)
        return button
    }

    /// `PayWithLinkButton` always uses Link's brand color, so `buttonTheme` only affects the Apple Pay button.
    private var applePayButtonStyle: PKPaymentButtonStyle {
        switch configuration.expressCheckoutElement.appearance.buttonTheme {
        case .light:
            return .white
        case .dark:
            return .black
        case .automatic:
            return .automatic
        }
    }

    @objc private func handleApplePayTapped() {
        confirm(.applePay)
    }

    @objc private func handleLinkTapped() {
        // TODO: Handle Link
    }

    private func confirm(_ paymentMethod: ExpressCheckoutElement.PaymentMethod) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let result = await self.delegate?.expressCheckoutElementShouldConfirm(
                paymentMethod,
                presentationWindow: window
            ) else { return }
            self.configuration.expressCheckoutElement.confirmHandler(result)
        }
    }
}
