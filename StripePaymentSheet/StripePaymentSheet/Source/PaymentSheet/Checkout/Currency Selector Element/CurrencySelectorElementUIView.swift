//
//  CurrencySelectorElementUIView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 4/6/26.
//

import Combine
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

/// A UIKit view that displays an Adaptive Pricing currency selector.
@_spi(STP)
@_spi(ReactNativeSDK)
@MainActor
public final class CurrencySelectorElementUIView: UIView {

    /// Whether the selector is enabled for user interaction.
    public var isEnabled: Bool = true {
        didSet {
            selectorView?.setEnabled(isEnabled)
        }
    }

    private weak var checkout: Checkout?
    private let appearance: CurrencySelectorElement.Appearance
    private let flagImageManager: AdaptivePricingFlagImageManager
    private var sessionCancellable: AnyCancellable?
    private var selectorView: TwoOptionSelectorView?
    private var lastSelectedCurrency: String?
    private let containerStackView = UIStackView()
    private lazy var errorLabel: UILabel = {
        let label = ElementsUI.makeErrorLabel(
            font: appearance.scaledFont(for: appearance.font, style: .caption1),
            textColor: appearance.danger
        )
        label.setHiddenIfNecessary(true)
        return label
    }()

    init(
        checkout: Checkout,
        appearance: CurrencySelectorElement.Appearance,
        flagImageManager: AdaptivePricingFlagImageManager
    ) {
        self.checkout = checkout
        self.appearance = appearance
        self.flagImageManager = flagImageManager
        super.init(frame: .zero)

        setupContainerStackView()
        handleSessionUpdate(checkout.session)
        sessionCancellable = checkout.$session
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.handleSessionUpdate(session)
            }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public var intrinsicContentSize: CGSize {
        guard !isHidden, selectorView != nil else {
            return .zero
        }
        return containerStackView.systemLayoutSizeFitting(
            CGSize(width: bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }

    private func setupContainerStackView() {
        containerStackView.axis = .vertical
        containerStackView.spacing = 6
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        containerStackView.addArrangedSubview(errorLabel)
    }

    private func handleSessionUpdate(_ session: Checkout.Session) {
        guard let (_, exchangeRateMeta, rawCurrency) =
                CurrencySelectorUtilities.adaptivePricingData(from: session)
        else {
            tearDown()
            return
        }

        let currency = CurrencySelectorUtilities.CurrencyCode(rawCurrency)
        clearError()

        if selectorView == nil {
            buildSelectorView(session: session, exchangeRateMeta: exchangeRateMeta, currency: currency)
        } else {
            updateSelectorItems(session: session, exchangeRateMeta: exchangeRateMeta)
        }

        lastSelectedCurrency = currency.apiValue
        updateCaption(currency: currency, exchangeRateMeta: exchangeRateMeta)
    }

    private func resolveLabelContent(session: Checkout.Session) -> CurrencySelectorElement.Appearance.LabelContent {
        guard case .automatic = appearance.labelContent else {
            return appearance.labelContent
        }
        return session.mode == .subscription ? .currencyCode : .amount
    }

    private func buildSelectorItems(
        session: Checkout.Session,
        exchangeRateMeta: STPCheckoutSessionExchangeRateMeta
    ) -> (left: TwoOptionSelectorItem, right: TwoOptionSelectorItem) {
        let resolvedLabelContent = resolveLabelContent(session: session)
        let flagFont = appearance.scaledFont(for: appearance.font, style: .footnote)
        return CurrencySelectorUtilities.buildSelectorItems(
            exchangeRateMeta: exchangeRateMeta,
            localizedPricesMetas: session.localizedPricesMetas,
            labelContent: resolvedLabelContent,
            flagPrefixProvider: { [weak flagImageManager] currency in
                flagImageManager?.flagIcon(for: currency, font: flagFont) ?? NSAttributedString()
            }
        )
    }

    private func updateSelectorItems(
        session: Checkout.Session,
        exchangeRateMeta: STPCheckoutSessionExchangeRateMeta
    ) {
        let (left, right) = buildSelectorItems(session: session, exchangeRateMeta: exchangeRateMeta)
        selectorView?.updateItems(left: left, right: right)
    }

    private func buildSelectorView(
        session: Checkout.Session,
        exchangeRateMeta: STPCheckoutSessionExchangeRateMeta,
        currency: CurrencySelectorUtilities.CurrencyCode
    ) {
        let (left, right) = buildSelectorItems(session: session, exchangeRateMeta: exchangeRateMeta)

        let newSelector = TwoOptionSelectorView(
            leftItem: left,
            rightItem: right,
            selectedItemId: currency.apiValue,
            appearance: appearance
        )
        newSelector.delegate = self
        newSelector.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.insertArrangedSubview(newSelector, at: 0)

        selectorView = newSelector
        newSelector.setEnabled(isEnabled)
        isHidden = false
        invalidateIntrinsicContentSize()
    }

    private func updateCaption(
        currency: CurrencySelectorUtilities.CurrencyCode,
        exchangeRateMeta: STPCheckoutSessionExchangeRateMeta
    ) {
        let caption = CurrencySelectorUtilities.caption(
            forSelectedCurrency: currency.apiValue,
            exchangeRateMeta: exchangeRateMeta
        )
        let detailText = CurrencySelectorUtilities.detailText(exchangeRateMeta: exchangeRateMeta)
        selectorView?.updateCaption(caption, detailText: detailText)
    }

    private func tearDown() {
        selectorView?.removeFromSuperview()
        selectorView = nil
        clearError()
        isHidden = true
        invalidateIntrinsicContentSize()
    }

    func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.setHiddenIfNecessary(false)
        invalidateIntrinsicContentSize()
    }

    func clearError() {
        guard errorLabel.text != nil else { return }
        errorLabel.text = nil
        errorLabel.setHiddenIfNecessary(true)
        invalidateIntrinsicContentSize()
    }
}

extension CurrencySelectorElementUIView: TwoOptionSelectorViewDelegate {
    func twoOptionSelectorView(_: TwoOptionSelectorView, didSelectItemWithId id: String) {
        let fromCurrency = lastSelectedCurrency
        lastSelectedCurrency = id
        selectorView?.setEnabled(false)

        Task { [weak self] in
            guard let self, let checkout else { return }
            do {
                try await checkout.selectCurrency(id)
                STPAnalyticsClient.sharedClient.log(
                    analytic: PaymentSheetAnalytic(
                        event: .adaptivePricingCurrencyToggled,
                        additionalParams: [:]
                    )
                )
            } catch {
                if let fromCurrency {
                    selectorView?.select(fromCurrency)
                    lastSelectedCurrency = fromCurrency
                }

                STPAnalyticsClient.sharedClient.log(
                    analytic: PaymentSheetAnalytic(
                        event: .adaptivePricingCurrencyToggledFailed,
                        additionalParams: error.serializeForV1Analytics()
                    )
                )
                showError(error.localizedDescription)
            }
            selectorView?.setEnabled(isEnabled)
        }
    }
}
