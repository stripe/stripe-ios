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

    private enum Constants {
        static let buttonHeight: CGFloat = 44
        static let buttonSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 6
    }

    // MARK: - Private Properties

    private let configuration: ExpressCheckoutElement.Configuration
    private let stackView = UIStackView()
    private var linkBrand: LinkBrand
    private weak var delegate: ExpressCheckoutElementDelegate?

    // MARK: - Init

    init(session: CheckoutController.Session, configuration: ExpressCheckoutElement.Configuration, delegate: ExpressCheckoutElementDelegate) {
        self.configuration = configuration
        self.delegate = delegate
        self.linkBrand = session.elementsSession.linkBrand ?? .link
        super.init(frame: .zero)

        stackView.axis = .vertical
        stackView.spacing = Constants.buttonSpacing
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

    /// Arranges `buttons` into no more than `appearance.buttonLayout.maxRows` rows of no more than `appearance.buttonLayout.maxColumns` columns.
    private func layoutButtons(_ buttons: [ExpressCheckoutElement.PaymentMethod]) {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for row in Self.buttonRows(for: buttons, layout: configuration.appearance.buttonLayout) {
            if row.count == 1, let method = row.first {
                stackView.addArrangedSubview(makeButton(for: method))
            } else {
                let rowStackView = UIStackView(arrangedSubviews: row.map { makeButton(for: $0) })
                rowStackView.axis = .horizontal
                rowStackView.spacing = Constants.buttonSpacing
                rowStackView.distribution = .fillEqually
                stackView.addArrangedSubview(rowStackView)
            }
        }
    }

    static func buttonRows(
        for buttons: [ExpressCheckoutElement.PaymentMethod],
        layout: ExpressCheckoutElement.Appearance.ButtonLayout
    ) -> [[ExpressCheckoutElement.PaymentMethod]] {
        guard !buttons.isEmpty else { return [] }

        let maxRows = layout.maxRows ?? buttons.count
        let maxColumns = layout.maxColumns ?? buttons.count
        let visibleButtonLimit = maxRows > buttons.count / maxColumns
            ? buttons.count
            : maxRows * maxColumns
        let visibleButtons = Array(buttons.prefix(visibleButtonLimit))
        let columnsNeeded = visibleButtons.count / maxRows + (visibleButtons.count % maxRows == 0 ? 0 : 1)
        let columns = min(
            maxColumns,
            max(columnsNeeded, 1)
        )

        return stride(from: 0, to: visibleButtons.count, by: columns).map {
            Array(visibleButtons[$0..<min($0 + columns, visibleButtons.count)])
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
        // `cornerConfiguration` doesn't work on PKPaymentButton, so set the radius directly.
        button.cornerRadius = LiquidGlassDetector.isEnabledInMerchantApp
            ? Constants.buttonHeight / 2
            : Constants.cornerRadius
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: Constants.buttonHeight).isActive = true
        button.addTarget(self, action: #selector(handleApplePayTapped), for: .touchUpInside)
        return button
    }

    private func makeLinkButton() -> UIView {
        let button = PayWithLinkButton(brand: linkBrand)
        if LiquidGlassDetector.isEnabledInMerchantApp {
            button.ios26_applyCapsuleCornerConfiguration()
        } else {
            button.cornerRadius = Constants.cornerRadius
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: Constants.buttonHeight).isActive = true
        button.addTarget(self, action: #selector(handleLinkTapped), for: .touchUpInside)
        return button
    }

    /// `PayWithLinkButton` always uses Link's brand color, so `buttonTheme` only affects the Apple Pay button.
    private var applePayButtonStyle: PKPaymentButtonStyle {
        switch configuration.appearance.buttonTheme {
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
        confirm(.link)
    }

    private func confirm(_ paymentMethod: ExpressCheckoutElement.PaymentMethod) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let result = await self.delegate?.expressCheckoutElementShouldConfirm(
                paymentMethod,
                presentationWindow: window
            ) else { return }
            self.configuration.confirmHandler(result)
        }
    }
}
