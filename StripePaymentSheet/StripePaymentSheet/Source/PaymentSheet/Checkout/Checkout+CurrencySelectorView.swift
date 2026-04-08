//
//  Checkout+CurrencySelectorView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 4/6/26.
//

import Combine
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

// MARK: - CurrencySelectorView

@_spi(CheckoutSessionsPreview)
extension Checkout {
    /// A standalone currency selector for Adaptive Pricing.
    ///
    /// Place this view on your cart or checkout page (near the total price) to let
    /// customers toggle between their local currency and the merchant's currency.
    ///
    /// The view automatically observes the ``CheckoutSession`` and:
    /// - Hides itself when Adaptive Pricing is not available
    /// - Shows two currency options with formatted amounts and exchange rate disclosure
    /// - Calls ``Checkout/selectCurrency(_:)`` when the customer taps a currency
    ///
    /// ```swift
    /// let currencySelector = Checkout.CurrencySelectorView(checkout: checkout)
    /// stackView.addArrangedSubview(currencySelector)
    /// ```
    @MainActor
    public final class CurrencySelectorView: UIView {

        // MARK: - Public Properties

        /// Whether the selector is enabled for user interaction.
        public var isEnabled: Bool = true {
            didSet {
                selectorView?.setEnabled(isEnabled)
            }
        }

        // MARK: - Private Properties

        private let checkout: Checkout
        private let appearance: Appearance
        private var selectorView: TwoOptionSelectorView?
        private var sessionCancellable: AnyCancellable?
        private var lastSelectedCurrency: String?

        // MARK: - Init

        /// Creates a currency selector view.
        /// - Parameters:
        ///   - checkout: The ``Checkout`` instance managing the session.
        ///   - appearance: Appearance configuration for the selector.
        public init(
            checkout: Checkout,
            appearance: Appearance = Appearance()
        ) {
            self.checkout = checkout
            self.appearance = appearance
            super.init(frame: .zero)

            // Evaluate current state synchronously
            handleSessionUpdate()

            // Observe future session changes
            sessionCancellable = checkout.$session
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
            guard !isHidden, let selectorView else {
                return .zero
            }
            return selectorView.systemLayoutSizeFitting(
                CGSize(width: bounds.width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
        }

        // MARK: - Private Methods

        /// Called when the session changes. Builds the selector on the first
        /// session that has adaptive pricing data, then updates the caption
        /// on subsequent changes. Hides the view if AP data is unavailable.
        private func handleSessionUpdate() {
            guard let (session, exchangeRateMeta, rawCurrency) =
                    CurrencySelectorElement.adaptivePricingData(from: checkout.session)
            else {
                tearDown()
                return
            }

            let currency = CurrencySelectorElement.CurrencyCode(rawCurrency)

            // Build the selector after inital sesison loading, after that just update the caption
            if selectorView == nil {
                buildSelectorView(session: session, exchangeRateMeta: exchangeRateMeta, currency: currency)
            }

            updateCaption(currency: currency, exchangeRateMeta: exchangeRateMeta)
        }

        private func buildSelectorView(
            session: STPCheckoutSession,
            exchangeRateMeta: STPCheckoutSessionExchangeRateMeta,
            currency: CurrencySelectorElement.CurrencyCode
        ) {
            let (left, right) = CurrencySelectorElement.buildSelectorItems(
                exchangeRateMeta: exchangeRateMeta,
                localizedPricesMetas: session.localizedPricesMetas
            )

            let psAppearance = appearance.asPaymentSheetAppearance()
            let newSelector = TwoOptionSelectorView(
                leftItem: left,
                rightItem: right,
                selectedItemId: currency.apiValue,
                appearance: psAppearance
            )
            newSelector.delegate = self

            newSelector.captionLabel.font = appearance.subtitleFont
            newSelector.captionLabel.textColor = appearance.captionColor

            newSelector.translatesAutoresizingMaskIntoConstraints = false
            addSubview(newSelector)
            NSLayoutConstraint.activate([
                newSelector.topAnchor.constraint(equalTo: topAnchor),
                newSelector.leadingAnchor.constraint(equalTo: leadingAnchor),
                newSelector.trailingAnchor.constraint(equalTo: trailingAnchor),
                newSelector.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])

            selectorView = newSelector
            newSelector.setEnabled(isEnabled)

            isHidden = false
            invalidateIntrinsicContentSize()
        }

        private func updateCaption(
            currency: CurrencySelectorElement.CurrencyCode,
            exchangeRateMeta: STPCheckoutSessionExchangeRateMeta
        ) {
            let caption = CurrencySelectorElement.caption(
                forSelectedCurrency: currency.apiValue,
                exchangeRateMeta: exchangeRateMeta
            )
            selectorView?.updateCaption(caption)
            selectorView?.captionLabel.font = appearance.subtitleFont
            selectorView?.captionLabel.textColor = appearance.captionColor
        }

        private func tearDown() {
            selectorView?.removeFromSuperview()
            selectorView = nil
            isHidden = true
            invalidateIntrinsicContentSize()
        }
    }
}

// MARK: - TwoOptionSelectorViewDelegate

extension Checkout.CurrencySelectorView: TwoOptionSelectorViewDelegate {
    func twoOptionSelectorView(_ view: TwoOptionSelectorView, didSelectItemWithId id: String) {
        let fromCurrency = lastSelectedCurrency
        lastSelectedCurrency = id

        // Disable interaction during the API call
        selectorView?.setEnabled(false)

        Task {
            do {
                try await checkout.selectCurrency(id)
                // Caption label updates automatically via handleSessionUpdate from session update
            } catch {
                // Revert to previous currency on error
                if let fromCurrency {
                    selectorView?.select(fromCurrency)
                    lastSelectedCurrency = fromCurrency
                }

                // TODO(porter) Figure out how to handle errors do we show an error message and alert the merchant?
            }
            selectorView?.setEnabled(isEnabled)
        }
    }
}
