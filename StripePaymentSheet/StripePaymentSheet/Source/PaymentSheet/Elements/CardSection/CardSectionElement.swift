//
//  CardSectionElement.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 3/24/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

/// A Element that contains a SectionElement for card details, whose view depends on the availability of card scanning:
/// If card scanning is available, it uses a custom view that adds card scanning. Otherwise, it uses the default SectionElement view.
/// It coordinates between the PAN and CVC fields.
final class CardSectionElement: ContainerElement {

    var elements: [Element] {
        return [cardSection]
    }

    weak var delegate: ElementDelegate?
    lazy var view: UIView = {
        #if !os(visionOS)
        if #available(iOS 13.0, macCatalyst 14, *), STPCardScanner.cardScanningAvailable {
            return CardSectionWithScannerView(
                cardSectionView: cardSection.view,
                opensCardScannerAutomatically: opensCardScannerAutomatically,
                delegate: self,
                theme: theme,
                analyticsHelper: analyticsHelper,
                linkAppearance: linkAppearance
            )
        } else {
            return cardSection.view
        }
        #else
            return cardSection.view
        #endif
    }()
    let cardSection: SectionElement
    let analyticsHelper: PaymentSheetAnalyticsHelper?
    let cardBrandFilter: CardBrandFilter
    let cardFundingFilter: CardFundingFilter
    /// Separate BIN controller for funding filtering to avoid polluting
    /// See: https://jira.corp.stripe.com/browse/RUN_MOBILESDK-5052
    private let fundingBinController: STPBINController = STPBINController()
    private let opensCardScannerAutomatically: Bool

    private let linkAppearance: LinkAppearance?

    struct DefaultValues {
        internal init(name: String? = nil, pan: String? = nil, cvc: String? = nil, expiry: String? = nil) {
            self.name = name
            self.pan = pan
            self.cvc = cvc
            self.expiry = expiry
        }

        let name: String?
        let pan: String?
        let cvc: String?
        let expiry: String?
    }

    // References to the underlying TextFieldElements
    let nameElement: TextFieldElement?
    let panElement: TextFieldElement
    let cardBrandChoiceElement: CardBrandChoiceElement?
    let cvcElement: TextFieldElement
    let expiryElement: TextFieldElement
    let theme: ElementsAppearance
    let preferredNetworks: [STPCardBrand]?
    let hostedSurface: HostedSurface

    init(
        collectName: Bool = false,
        defaultValues: DefaultValues = .init(),
        preferredNetworks: [STPCardBrand]? = nil,
        cardBrandChoiceEligible: Bool = false,
        enableCBCRedesign: Bool = false,
        hostedSurface: HostedSurface,
        theme: ElementsAppearance = .default,
        analyticsHelper: PaymentSheetAnalyticsHelper?,
        cardBrandFilter: CardBrandFilter = .default,
        cardFundingFilter: CardFundingFilter = .default,
        opensCardScannerAutomatically: Bool = false,
        linkAppearance: LinkAppearance? = nil
    ) {
        self.hostedSurface = hostedSurface
        self.theme = theme
        self.analyticsHelper = analyticsHelper
        self.cardBrandFilter = cardBrandFilter
        self.cardFundingFilter = cardFundingFilter
        self.opensCardScannerAutomatically = opensCardScannerAutomatically
        let nameElement = collectName
            ? PaymentMethodElementWrapper(
                TextFieldElement.NameConfiguration(
                    type: .full,
                    defaultValue: defaultValues.name,
                    label: STPLocalizedString("Name on card", "Label for name on card field")),
                theme: theme
            ) { field, params in
                params.paymentMethodParams.nonnil_billingDetails.name = field.text
                return params
            }
            : nil
        var cardBrandSelector: PaymentMethodElementWrapper<CardBrandChoiceElement>?
        if cardBrandChoiceEligible {
            cardBrandSelector = PaymentMethodElementWrapper(CardBrandChoiceElement(enableCBCRedesign: enableCBCRedesign, theme: theme)) { field, params in
                let cardBrand = field.selectedBrand ?? .unknown
                // Only set preferred networks for the confirm params if we have more than 1 brand fetched
                if (cardBrandSelector?.element.brandCount ?? 1) > 1 {
                    cardParams(for: params).networks = STPPaymentMethodCardNetworksParams(preferred: cardBrand != .unknown ? STPCardBrandUtilities.apiValue(from: cardBrand) : nil)
                }
                analyticsHelper?.logCardBrandSelected(hostedSurface: hostedSurface, cardBrand: cardBrand)
                return params
            }
        }
        let panElement = PaymentMethodElementWrapper(TextFieldElement.PANConfiguration(
            defaultValue: defaultValues.pan,
            cardBrandChoiceElement: cardBrandSelector?.element,
            cardBrandFilter: cardBrandFilter,
            cardFundingFilter: cardFundingFilter,
            fundingBinController: fundingBinController
        ), theme: theme) { field, params in
            cardParams(for: params).number = field.text
            return params
        }
        let cvcElementConfiguration = TextFieldElement.CVCConfiguration(defaultValue: defaultValues.cvc) {
            return STPCardValidator.brand(forNumber: panElement.element.text)
        }
        let cvcElement = PaymentMethodElementWrapper(cvcElementConfiguration, theme: theme) { field, params in
            cardParams(for: params).cvc = field.text
            return params
        }
        let expiryElement = PaymentMethodElementWrapper(TextFieldElement.ExpiryDateConfiguration(defaultValue: defaultValues.expiry), theme: theme) { field, params in
            if let month = Int(field.text.prefix(2)) {
                cardParams(for: params).expMonth = NSNumber(value: month)
            }
            if let year = Int(field.text.suffix(2)) {
                cardParams(for: params).expYear = NSNumber(value: year)
            }
            return params
        }

        let sectionTitle: String? = {
            if #available(iOS 13.0, macCatalyst 14, *) {
                return nil
            } else {
                return String.Localized.card_information
            }
        }()

        let allSubElements: [Element?] = [
            nameElement,
            panElement, SectionElement.HiddenElement(cardBrandSelector),
            SectionElement.MultiElementRow([expiryElement, cvcElement], theme: theme),
        ]
        let subElements = allSubElements.compactMap { $0 }
        self.cardSection = SectionElement(
            title: sectionTitle,
            elements: subElements,
            theme: theme
        )

        self.nameElement = nameElement?.element
        self.panElement = panElement.element
        self.cardBrandChoiceElement = cardBrandSelector?.element
        self.cvcElement = cvcElement.element
        self.expiryElement = expiryElement.element
        self.preferredNetworks = preferredNetworks
        self.lastPanElementValidationState = panElement.validationState
        self.linkAppearance = linkAppearance
        cardSection.delegate = self
    }

    // MARK: - ElementDelegate
    private var cardBrand: STPCardBrand = .unknown
    private var selectedBrand: STPCardBrand? {
        guard let cardBrandChoiceElement = cardBrandChoiceElement else {
            return nil
        }
        return cardBrandChoiceElement.selectedBrand
    }

    /// Tracks the last known validation state of the PAN element, so that we can know when it changes from invalid to valid
    var lastPanElementValidationState: ElementValidationState
    var lastDisallowedCardBrandLogged: STPCardBrand?
    var hasLoggedExpectedExtraDigitsButUserEntered16: Bool = false
    func didUpdate(element: Element) {
        // Update the CVC field if the card brand changes
        let cardBrand = selectedBrand ?? STPCardValidator.brand(forNumber: panElement.text)
        if self.cardBrand != cardBrand {
            self.cardBrand = cardBrand
            cvcElement.setText(cvcElement.text) // A hack to get the CVC to update
        }

        fetchAndUpdateCardBrands()
        fetchAndCacheCardFunding()
        updateCBCTooltipVisibility()

        /// Send an analytic whenever the card number field is completed
        if lastPanElementValidationState.isValid != panElement.validationState.isValid {
            lastPanElementValidationState = panElement.validationState
            if case .valid = panElement.validationState {
                STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .paymentSheetCardNumberCompleted)
            }
        }

        // If the user entered 16 digits and exited the field, but our PAN length data
        // indicates that we need more (maybe 19 digits?), then our data might be wrong.
        // Send an alert so we can measure how often this happens.
        if case .invalid(let error, _) = panElement.validationState,
               let specificError = error as? TextFieldElement.PANConfiguration.Error,
           case .incomplete = specificError,
           !panElement.isEditing,
           !hasLoggedExpectedExtraDigitsButUserEntered16 {
            if panElement.text.count == 16 {
                STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .cardMetadataExpectedExtraDigitsButUserEntered16ThenSwitchedFields)
                hasLoggedExpectedExtraDigitsButUserEntered16 = true
            }
        }

        // Send an analytic if we are disallowing a card brand
        if case .invalid(let error, _) = panElement.validationState,
           let specificError = error as? TextFieldElement.PANConfiguration.Error,
           case .disallowedBrand(let brand) = specificError,
           lastDisallowedCardBrandLogged != brand {

            STPAnalyticsClient.sharedClient.logPaymentSheetEvent(
                event: .paymentSheetDisallowedCardBrand,
                params: ["brand": STPCardBrandUtilities.apiValue(from: brand)]
            )
            lastDisallowedCardBrandLogged = brand
        }

        delegate?.didUpdate(element: self)
    }

    // MARK: - Card funding check

    /// Fetches BIN metadata from the card metadata service and caches it in `STPBINController`.
    func fetchAndCacheCardFunding() {
        guard cardFundingFilter != .default else {
            return
        }
        let binPrefix = String(panElement.text.prefix(6))
        guard panElement.text.count >= 6 else {
            return
        }

        fundingBinController.retrieveBINRanges(
            forPrefix: binPrefix,
            recordErrorsAsSuccess: false,
            onlyFetchForVariableLengthBINs: false
        ) { [weak self] _ in
            guard let self = self else { return }
            // Trigger re-validation so warningLabel can read the now-cached funding data
            delegate?.didUpdate(element: self)
        }
    }

    // MARK: Card brand choice
    private lazy var cbcTooltipView: UIView = {
        let label = UILabel()
        label.text = STPLocalizedString("Choose a card brand", "Tooltip prompting user to select their card brand when a co-branded card is detected")
        label.font = theme.fonts.footnote
        label.textColor = theme.colors.textFieldText
        label.numberOfLines = 0

        let container = UIView()
        container.backgroundColor = theme.colors.componentBackground
        container.applyCornerRadius(appearance: theme)
        container.layer.applyShadow(shadow: theme.shadow)
        container.layer.borderColor = theme.colors.border.cgColor
        container.layer.borderWidth = theme.borderWidth

        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
        ])
        container.frame.size = container.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return container
    }()
    /// Latches `true` once the user selects a brand; suppresses the tooltip if they later
    /// toggle the selection off. Reset when the set of available brands changes.
    private var hasBrandBeenSelected = false
    private var cardBrands = Set<STPCardBrand>()
    func fetchAndUpdateCardBrands() {
        // Only fetch card brands if we have at least 8 digits in the pan
        guard let cardBrandChoiceElement = cardBrandChoiceElement, panElement.text.count >= 8 else {
            // Clear any previously fetched card brands from the dropdown
            if !self.cardBrands.isEmpty {
                self.cardBrands = Set<STPCardBrand>()
                self.hasBrandBeenSelected = false
                cardBrandChoiceElement?.update(cardBrands: self.cardBrands, disallowedCardBrands: Set<STPCardBrand>())
                self.panElement.setText(self.panElement.text) // Hack to get the accessory view to update
            }
            return
        }

        var fetchedCardBrands = Set<STPCardBrand>()
        let hadBrands = !cardBrands.isEmpty
        STPCardValidator.possibleBrands(forNumber: panElement.text) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let brands):
                fetchedCardBrands = brands
            case .failure:
                // If we fail to fetch card brands fall back to normal card brand detection
                fetchedCardBrands = Set<STPCardBrand>()
            }

            // If we had no brands but now have brands the CBC indicator will appear, log the analytic
            if !hadBrands, !fetchedCardBrands.isEmpty {
                STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: self.hostedSurface.analyticEvent(for: .displayCardBrandDropdownIndicator))
            }

            if self.cardBrands != fetchedCardBrands {
                self.cardBrands = fetchedCardBrands
                self.hasBrandBeenSelected = false
                let disallowedCardBrands = fetchedCardBrands.filter { !self.cardBrandFilter.isAccepted(cardBrand: $0) }

                cardBrandChoiceElement.update(
                    cardBrands: fetchedCardBrands,
                    disallowedCardBrands: disallowedCardBrands
                )

                // Prioritize merchant preference if we did not have brands prior to calling .possibleBrands, otherwise use default logic
                if !hadBrands, let brandToSelect = hasPreferredBrand(fetchedCardBrands: fetchedCardBrands, disallowedCardBrands: disallowedCardBrands) {
                    selectBrandIfNecessary(brandToSelect, in: cardBrandChoiceElement)
                } else if let brandToSelect = useDefaultSelectionLogic(fetchedCardBrands: fetchedCardBrands, disallowedCardBrands: disallowedCardBrands) {
                    selectBrandIfNecessary(brandToSelect, in: cardBrandChoiceElement)
                }

                self.panElement.setText(self.panElement.text) // Hack to get the accessory view to update
            }
        }
    }

    /// Show the tooltip when the PAN field is in focus, the card brand selector is visible
    /// (multiple brands), and no brand has been selected. Hide it otherwise.
    private func updateCBCTooltipVisibility() {
        if cardBrandChoiceElement?.selectedBrand != nil {
            hasBrandBeenSelected = true
        }

        let shouldShow = panElement.isEditing
            && cardBrands.count > 1
            && !hasBrandBeenSelected

        let tooltip = cbcTooltipView
        if shouldShow {
            // Position trailing-aligned below the PAN field.
            let panFrame = panElement.view.convert(panElement.view.bounds, to: view)
            tooltip.frame.origin = CGPoint(
                x: panFrame.maxX - tooltip.frame.width - 4,
                y: panFrame.maxY + 4
            )

            if tooltip.superview == nil {
                tooltip.alpha = 0
                view.addSubview(tooltip)
            }
            view.bringSubviewToFront(tooltip)

            UIView.animate(withDuration: 0.2) {
                tooltip.alpha = 1
            }
        } else if tooltip.alpha > 0 {
            UIView.animate(withDuration: 0.2) {
                tooltip.alpha = 0
            }
        }
    }

    // Select the first brand in the fetched brands that appears earliest in the merchants preferred networks
    func hasPreferredBrand(fetchedCardBrands: Set<STPCardBrand>, disallowedCardBrands: Set<STPCardBrand>) -> STPCardBrand? {
        guard let preferredNetworks = self.preferredNetworks,
              let brandToSelect = preferredNetworks.first(where: { fetchedCardBrands.contains($0) && !disallowedCardBrands.contains($0) }) else {
            return nil
        }

        return brandToSelect

    }

    // If we only fetched one card brand that is not disallowed, auto select it.
    // This case typically only occurs when card brand filtering is used with CBC and one of the fetched brands is filtered out.
    func useDefaultSelectionLogic(fetchedCardBrands: Set<STPCardBrand>, disallowedCardBrands: Set<STPCardBrand>) -> STPCardBrand? {
        let validBrands = fetchedCardBrands.subtracting(disallowedCardBrands)
        guard validBrands.count == 1,
              !disallowedCardBrands.isEmpty,
              let brandToSelect = validBrands.first else {
            return nil
        }
        return brandToSelect
    }

    private func selectBrandIfNecessary(_ brand: STPCardBrand, in cardBrandChoiceElement: CardBrandChoiceElement) {
        guard cardBrandChoiceElement.selectedBrand != brand else { return }
        if cardBrandChoiceElement.enableCBCRedesign {
            cardBrandChoiceElement.selectorElement?.select(brand.makeCardBrandItem(), shouldAutoAdvance: false)
        } else {
            if let indexToSelect = cardBrandChoiceElement.dropdownElement?.items.firstIndex(where: { $0.rawData == STPCardBrandUtilities.apiValue(from: brand) }) {
                cardBrandChoiceElement.dropdownElement?.select(index: indexToSelect, shouldAutoAdvance: false)
            }
        }
    }
}

// MARK: - Helpers
/// A DRY helper to ensure `STPPaymentMethodCardParams` is present on `intentConfirmParams.paymentMethodParams`.
internal func cardParams(for intentParams: IntentConfirmParams) -> STPPaymentMethodCardParams {
    guard let cardParams = intentParams.paymentMethodParams.card else {
        let cardParams = STPPaymentMethodCardParams()
        intentParams.paymentMethodParams.card = cardParams
        return cardParams
    }
    return cardParams
}

#if !os(visionOS)
// MARK: - CardSectionWithScannerViewDelegate

extension CardSectionElement: CardSectionWithScannerViewDelegate {
    func didScanCard(cardParams: STPPaymentMethodCardParams) {
        let expiryString: String = {
            guard let expMonth = cardParams.expMonth, let expYear = cardParams.expYear else {
                return ""
            }
            return String(format: "%02d%02d", expMonth.intValue, expYear.intValue)
        }()

        // Populate the fields with the card params we scanned
        panElement.setText(cardParams.number ?? "")
        expiryElement.setText(expiryString)

        // Slightly hacky way to focus the next un-populated field
        if let lastCompletedElement = [panElement, expiryElement].last(where: { !$0.text.isEmpty }) {
            lastCompletedElement.delegate?.continueToNextField(element: lastCompletedElement)
        }
    }
}
#endif
