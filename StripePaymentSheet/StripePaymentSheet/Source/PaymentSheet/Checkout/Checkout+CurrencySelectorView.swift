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
    /// The view automatically observes the ``Checkout`` session and:
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
        private var previousCurrency: String?

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
            rebuildIfNeeded()

            // Observe future session changes
            sessionCancellable = checkout.$session
                .dropFirst()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.rebuildIfNeeded()
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

        /// Tears down and recreates the internal `TwoOptionSelectorView` from the
        /// current session state. If adaptive pricing data is missing or inactive
        /// the view hides itself; otherwise it builds fresh selector items and
        /// caption text from the session's exchange-rate and localized-price metadata.
        private func rebuildIfNeeded() {
            guard StripePaymentSheet.CurrencySelectorElement.isAdaptivePricingAvailable(session: checkout.session),
                  let session = checkout.session as? STPCheckoutSession,
                  let exchangeRateMeta = session.exchangeRateMeta,
                  let currency = session.currency
            else {
                tearDown()
                return
            }

            // Build selector items using existing CurrencySelectorElement helpers
            let (left, right) = StripePaymentSheet.CurrencySelectorElement.buildSelectorItems(
                exchangeRateMeta: exchangeRateMeta,
                localizedPricesMetas: session.localizedPricesMetas
            )
            let caption = StripePaymentSheet.CurrencySelectorElement.caption(
                forSelectedCurrency: currency.lowercased(),
                exchangeRateMeta: exchangeRateMeta
            )

            // Remove old selector
            selectorView?.removeFromSuperview()

            // Create new selector with bridged appearance
            let psAppearance = appearance.asPaymentSheetAppearance()
            let newSelector = TwoOptionSelectorView(
                leftItem: left,
                rightItem: right,
                selectedItemId: currency.lowercased(),
                caption: caption,
                appearance: psAppearance
            )
            newSelector.delegate = self

            // Override caption label styling with our custom appearance.
            // Note: TwoOptionSelectorView.updateCaption() only sets text/visibility,
            // not font/color, so these overrides are safe.
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
            previousCurrency = currency.lowercased()

            isHidden = false
            invalidateIntrinsicContentSize()
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
        let fromCurrency = previousCurrency
        previousCurrency = id

        // Update caption immediately
        if let session = checkout.session as? STPCheckoutSession,
           let exchangeRateMeta = session.exchangeRateMeta {
            let caption = StripePaymentSheet.CurrencySelectorElement.caption(
                forSelectedCurrency: id,
                exchangeRateMeta: exchangeRateMeta
            )
            selectorView?.updateCaption(caption)
            selectorView?.captionLabel.font = appearance.subtitleFont
            selectorView?.captionLabel.textColor = appearance.captionColor
        }

        // Disable interaction during the API call
        selectorView?.setEnabled(false)

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await self.checkout.selectCurrency(id)
            } catch {
                // Revert to previous currency on error
                if let fromCurrency {
                    self.selectorView?.select(fromCurrency)
                    self.previousCurrency = fromCurrency
                }
            }
            // Re-enable after API call completes (rebuildIfNeeded will also fire from session update)
            self.selectorView?.setEnabled(self.isEnabled)
        }
    }
}
