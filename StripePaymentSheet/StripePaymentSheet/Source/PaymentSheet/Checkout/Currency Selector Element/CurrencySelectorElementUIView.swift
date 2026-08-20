//
//  CurrencySelectorElementUIView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 4/6/26.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

/// A UIKit view that displays an Adaptive Pricing currency selector.
@_spi(STP)
@_spi(ReactNativeSDK)
@MainActor
public final class CurrencySelectorElementUIView: UIView {

    /// Updates interaction and disabled styling while retaining UIKit's native state as the source of truth.
    func setEnabled(_ enabled: Bool) {
        isUserInteractionEnabled = enabled
        selectorView?.setEnabled(enabled)
    }

    private weak var delegate: CurrencySelectorElementDelegate?
    private let appearance: CurrencySelectorElement.Appearance
    private let checkoutSessionId: String
    private let flagImageManager = AdaptivePricingFlagImageManager()
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

    init?(
        session: CheckoutController.Session,
        delegate: CurrencySelectorElementDelegate,
        appearance: CurrencySelectorElement.Appearance
    ) async {
        guard let (_, exchangeRateMeta, rawCurrency) = CurrencySelectorUtilities.adaptivePricingData(from: session) else {
            return nil
        }
        self.delegate = delegate
        self.appearance = appearance
        self.checkoutSessionId = session.id
        super.init(frame: .zero)

        await flagImageManager.prefetchFlagImages(for: session)
        setupContainerStackView()
        let currency = CurrencySelectorUtilities.CurrencyCode(rawCurrency)
        buildSelectorView(session: session, exchangeRateMeta: exchangeRateMeta, currency: currency)
        lastSelectedCurrency = currency.apiValue
        updateCaption(currency: currency, exchangeRateMeta: exchangeRateMeta)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public var intrinsicContentSize: CGSize {
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

    func update(with session: CheckoutController.Session) {
        guard let (_, exchangeRateMeta, rawCurrency) =
                CurrencySelectorUtilities.adaptivePricingData(from: session)
        else {
            assertionFailure("Adaptive Pricing data unexpectedly became unavailable")
            return
        }

        let currency = CurrencySelectorUtilities.CurrencyCode(rawCurrency)
        clearError()
        updateSelectorItems(session: session, exchangeRateMeta: exchangeRateMeta)
        lastSelectedCurrency = currency.apiValue
        updateCaption(currency: currency, exchangeRateMeta: exchangeRateMeta)
    }

    private func resolveLabelContent() -> CurrencySelectorElement.Appearance.LabelContent {
        guard case .automatic = appearance.labelContent else {
            return appearance.labelContent
        }
        return .amount
    }

    private func buildSelectorItems(
        session: CheckoutController.Session,
        exchangeRateMeta: CheckoutController.Session.ExchangeRateMeta
    ) -> (left: TwoOptionSelectorItem, right: TwoOptionSelectorItem) {
        let resolvedLabelContent = resolveLabelContent()
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
        session: CheckoutController.Session,
        exchangeRateMeta: CheckoutController.Session.ExchangeRateMeta
    ) {
        let (left, right) = buildSelectorItems(session: session, exchangeRateMeta: exchangeRateMeta)
        selectorView?.updateItems(left: left, right: right)
    }

    private func buildSelectorView(
        session: CheckoutController.Session,
        exchangeRateMeta: CheckoutController.Session.ExchangeRateMeta,
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
        newSelector.setEnabled(isUserInteractionEnabled)
        invalidateIntrinsicContentSize()
    }

    private func updateCaption(
        currency: CurrencySelectorUtilities.CurrencyCode,
        exchangeRateMeta: CheckoutController.Session.ExchangeRateMeta
    ) {
        let caption = CurrencySelectorUtilities.caption(
            forSelectedCurrency: currency.apiValue,
            exchangeRateMeta: exchangeRateMeta
        )
        let detailText = CurrencySelectorUtilities.detailText(exchangeRateMeta: exchangeRateMeta)
        selectorView?.updateCaption(caption, detailText: detailText)
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
            guard let self, let delegate else { return }
            do {
                try await delegate.selectCurrency(id)
                STPAnalyticsClient.sharedClient.log(
                    analytic: PaymentSheetAnalytic(
                        event: .adaptivePricingCurrencyToggled,
                        additionalParams: ["checkout_session_id": checkoutSessionId]
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
                        additionalParams: error.serializeForV1Analytics().merging(
                            ["checkout_session_id": checkoutSessionId]
                        ) { _, checkoutSessionId in checkoutSessionId }
                    )
                )
                showError(error.localizedDescription)
            }
            selectorView?.setEnabled(isUserInteractionEnabled)
        }
    }
}
