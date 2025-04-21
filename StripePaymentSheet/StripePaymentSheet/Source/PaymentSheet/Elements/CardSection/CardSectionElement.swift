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
        #if !canImport(CompositorServices)
        if #available(iOS 13.0, macCatalyst 14, *), STPCardScanner.cardScanningAvailable {
            return CardSectionWithScannerView(cardSectionView: cardSection.view, delegate: self, theme: theme, analyticsHelper: analyticsHelper)
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
    let cardBrandDropDown: DropdownFieldElement?
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
        hostedSurface: HostedSurface,
        theme: ElementsAppearance = .default,
        analyticsHelper: PaymentSheetAnalyticsHelper?,
        cardBrandFilter: CardBrandFilter = .default
    ) {
        self.hostedSurface = hostedSurface
        self.theme = theme
        self.analyticsHelper = analyticsHelper
        self.cardBrandFilter = cardBrandFilter
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
        var cardBrandDropDown: PaymentMethodElementWrapper<DropdownFieldElement>?
        if cardBrandChoiceEligible {
            cardBrandDropDown = PaymentMethodElementWrapper(DropdownFieldElement.makeCardBrandDropdown(theme: theme)) { field, params in
                let cardBrand = STPCard.brand(from: field.selectedItem.rawData)
                // Only set preferred networks for the confirm params if we have more than 1 brand fetched
                if (cardBrandDropDown?.element.nonPlacerholderItems.count ?? 1) > 1 {
                    cardParams(for: params).networks = STPPaymentMethodCardNetworksParams(preferred: cardBrand != .unknown ? STPCardBrandUtilities.apiValue(from: cardBrand) : nil)
                }
                analyticsHelper?.logCardBrandSelected(hostedSurface: hostedSurface, cardBrand: cardBrand)
                return params
            }
        }
        let panElement = PaymentMethodElementWrapper(TextFieldElement.PANConfiguration(defaultValue: defaultValues.pan,
                                                                                       cardBrandDropDown: cardBrandDropDown?.element, cardFilter: cardBrandFilter), theme: theme) { field, params in
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
            panElement, SectionElement.HiddenElement(cardBrandDropDown),
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
        self.cardBrandDropDown = cardBrandDropDown?.element
        self.cvcElement = cvcElement.element
        self.expiryElement = expiryElement.element
        self.preferredNetworks = preferredNetworks
        self.lastPanElementValidationState = panElement.validationState
        cardSection.delegate = self
    }

    // MARK: - ElementDelegate
    private var cardBrand: STPCardBrand = .unknown
    private var selectedBrand: STPCardBrand? {
        guard let cardBrandDropDown = cardBrandDropDown,
              let cardBrandCaseIndex = Int(cardBrandDropDown.selectedItem.rawData) else {
            return nil
        }

        return .init(rawValue: cardBrandCaseIndex) ?? .unknown
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

    // MARK: Card brand choice
    private var cardBrands = Set<STPCardBrand>()
    func fetchAndUpdateCardBrands() {
        // Only fetch card brands if we have at least 8 digits in the pan
        guard let cardBrandDropDown = cardBrandDropDown, panElement.text.count >= 8 else {
            // Clear any previously fetched card brands from the dropdown
            if !self.cardBrands.isEmpty {
                self.cardBrands = Set<STPCardBrand>()
                cardBrandDropDown?.update(items: DropdownFieldElement.items(from: self.cardBrands, disallowedCardBrands: Set<STPCardBrand>(), theme: self.theme))
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
                let disallowedCardBrands = fetchedCardBrands.filter { !self.cardBrandFilter.isAccepted(cardBrand: $0) }

                cardBrandDropDown.update(items: DropdownFieldElement.items(
                    from: fetchedCardBrands,
                    disallowedCardBrands: disallowedCardBrands,
                    theme: self.theme
                ))

                // Prioritize merchant preference if we did not have brands prior to calling .possibleBrands, otherwise use default logic
                if !hadBrands, let indexToSelect = hasPreferredBrandIndex(fetchedCardBrands: fetchedCardBrands, disallowedCardBrands: disallowedCardBrands, cardBrandDropDown: cardBrandDropDown) {
                    cardBrandDropDown.select(index: indexToSelect, shouldAutoAdvance: false)
                } else if let indexToSelect = useDefaultSelectionLogic(disallowedCardBrands: disallowedCardBrands, cardBrandDropDown: cardBrandDropDown) {
                    cardBrandDropDown.select(index: indexToSelect, shouldAutoAdvance: false)
                }

                self.panElement.setText(self.panElement.text) // Hack to get the accessory view to update
            }
        }
    }

    // Select the first brand in the fetched brands that appears earliest in the merchants preferred networks
    func hasPreferredBrandIndex(fetchedCardBrands: Set<STPCardBrand>, disallowedCardBrands: Set<STPCardBrand>, cardBrandDropDown: DropdownFieldElement) -> Int? {
        guard let preferredNetworks = self.preferredNetworks,
              let brandToSelect = preferredNetworks.first(where: { fetchedCardBrands.contains($0) && !disallowedCardBrands.contains($0) }),
              let indexToSelect = cardBrandDropDown.items.firstIndex(where: { $0.rawData == STPCardBrandUtilities.apiValue(from: brandToSelect) }) else {
            return nil
        }

        return indexToSelect

    }

    // If we only fetched one card brand that is not disallowed, auto select it.
    // This case typically only occurs when card brand filtering is used with CBC and one of the fetched brands is filtered out.
    func useDefaultSelectionLogic(disallowedCardBrands: Set<STPCardBrand>, cardBrandDropDown: DropdownFieldElement) -> Int? {
        let validBrandSelections = cardBrandDropDown.items.filter { !$0.isPlaceholder && !$0.isDisabled }
        guard validBrandSelections.count == 1,
              !disallowedCardBrands.isEmpty,
              let firstItem = validBrandSelections.first,
              let indexToSelect = cardBrandDropDown.items.firstIndex(where: { $0.rawData == firstItem.rawData }) else {
            return nil
        }

        return indexToSelect
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

#if !canImport(CompositorServices)
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
