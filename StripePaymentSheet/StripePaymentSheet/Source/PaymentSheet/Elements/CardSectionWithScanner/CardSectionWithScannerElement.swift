//
//  CardSectionWithScannerElement.swift
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
final class CardSection: ContainerElement {

    var elements: [Element] {
        return [cardSection]
    }

    weak var delegate: ElementDelegate?
    lazy var view: UIView = {
        #if !canImport(CompositorServices)
        if #available(iOS 13.0, macCatalyst 14, *), STPCardScanner.cardScanningAvailable {
            return CardSectionWithScannerView(cardSectionView: cardSection.view, delegate: self, theme: theme)
        } else {
            return cardSection.view
        }
        #else
            return cardSection.view
        #endif
    }()
    let cardSection: SectionElement

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
    let theme: ElementsUITheme
    let preferredNetworks: [STPCardBrand]?
    let hostedSurface: HostedSurface

    init(
        collectName: Bool = false,
        defaultValues: DefaultValues = .init(),
        preferredNetworks: [STPCardBrand]? = nil,
        cardBrandChoiceEligible: Bool = false,
        hostedSurface: HostedSurface,
        theme: ElementsUITheme = .default
    ) {
        self.hostedSurface = hostedSurface
        self.theme = theme
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
                cardParams(for: params).networks = STPPaymentMethodCardNetworksParams(preferred: cardBrand != .unknown ? STPCardBrandUtilities.apiValue(from: cardBrand) : nil)
                return params
            }
        }
        let panElement = PaymentMethodElementWrapper(TextFieldElement.PANConfiguration(defaultValue: defaultValues.pan,
                                                                                       cardBrandDropDown: cardBrandDropDown?.element), theme: theme) { field, params in
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

        // Hook up CBC analytics after self is initialized
        self.cardBrandDropDown?.didPresent = { [weak self] in
            guard let self = self, let cardBrandDropDown = self.cardBrandDropDown else { return }
            let selectedCardBrand = cardBrandDropDown.selectedItem.rawData.toCardBrand ?? .unknown
            let params = ["selected_card_brand": STPCardBrandUtilities.apiValue(from: selectedCardBrand), "cbc_event_source": "add"]
            STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: self.hostedSurface.analyticEvent(for: .openCardBrandDropdown),
                                                                 params: params)
        }

        self.cardBrandDropDown?.didTapClose = { [weak self] in
            guard let self = self, let cardBrandDropDown = self.cardBrandDropDown else { return }
            let selectedCardBrand = cardBrandDropDown.selectedItem.rawData.toCardBrand ?? .unknown
            STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: self.hostedSurface.analyticEvent(for: .closeCardBrandDropDown),
                                                                 params: ["selected_card_brand": STPCardBrandUtilities.apiValue(from: selectedCardBrand)])
        }
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
                cardBrandDropDown?.update(items: DropdownFieldElement.items(from: self.cardBrands, theme: self.theme))
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
                cardBrandDropDown.update(items: DropdownFieldElement.items(from: fetchedCardBrands, theme: self.theme))

                // If we didn't previously have brands but now have them select based on merchant preference
                // Select the first brand in the fetched brands that appears earliest in the merchants preferred networks
                if !hadBrands,
                   let preferredNetworks = self.preferredNetworks,
                   let brandToSelect = preferredNetworks.first(where: { fetchedCardBrands.contains($0) }),
                   let indexToSelect = cardBrandDropDown.items.firstIndex(where: { $0.rawData == STPCardBrandUtilities.apiValue(from: brandToSelect) }) {
                    cardBrandDropDown.select(index: indexToSelect, shouldAutoAdvance: false)
                }

                self.panElement.setText(self.panElement.text) // Hack to get the accessory view to update
            }
        }
    }
}

// MARK: - Helpers
/// A DRY helper to ensure `STPPaymentMethodCardParams` is present on `intentConfirmParams.paymentMethodParams`.
private func cardParams(for intentParams: IntentConfirmParams) -> STPPaymentMethodCardParams {
    guard let cardParams = intentParams.paymentMethodParams.card else {
        let cardParams = STPPaymentMethodCardParams()
        intentParams.paymentMethodParams.card = cardParams
        return cardParams
    }
    return cardParams
}

#if !canImport(CompositorServices)
// MARK: - CardSectionWithScannerViewDelegate

extension CardSection: CardSectionWithScannerViewDelegate {
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
