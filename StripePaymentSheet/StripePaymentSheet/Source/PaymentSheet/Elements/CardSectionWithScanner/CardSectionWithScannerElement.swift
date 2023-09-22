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
        if #available(iOS 13.0, macCatalyst 14, *), STPCardScanner.cardScanningAvailable {
            return CardSectionWithScannerView(cardSectionView: cardSection.view, delegate: self, theme: theme)
        } else {
            return cardSection.view
        }
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

    init(
        collectName: Bool = false,
        defaultValues: DefaultValues = .init(),
        cardBrandChoiceEligible: Bool = false,
        theme: ElementsUITheme = .default
    ) {
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
        var cardBrandDropDown: DropdownFieldElement?
        if cardBrandChoiceEligible {
            cardBrandDropDown = DropdownFieldElement.makeCardBrandDropdown(theme: theme)
        }
        let panElement = PaymentMethodElementWrapper(TextFieldElement.PANConfiguration(defaultValue: defaultValues.pan,
                                                                                       cardBrandDropDown: cardBrandDropDown), theme: theme) { field, params in
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

        var allSubElements: [Element?] = [
            nameElement,
            panElement,
            SectionElement.MultiElementRow([expiryElement, cvcElement], theme: theme),
        ]
        if let cardBrandDropDown = cardBrandDropDown {
            allSubElements += [SectionElement.HiddenElement(element: cardBrandDropDown)]
        }
        let subElements = allSubElements.compactMap { $0 }
        self.cardSection = SectionElement(
            title: sectionTitle,
            elements: subElements,
            theme: theme
        )

        self.nameElement = nameElement?.element
        self.panElement = panElement.element
        self.cardBrandDropDown = cardBrandDropDown
        self.cvcElement = cvcElement.element
        self.expiryElement = expiryElement.element
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

    func didUpdate(element: Element) {
        // Update the CVC field if the card brand changes
        let cardBrand = selectedBrand ?? STPCardValidator.brand(forNumber: panElement.text)
        if self.cardBrand != cardBrand {
            self.cardBrand = cardBrand
            cvcElement.setText(cvcElement.text) // A hack to get the CVC to update
        }

        fetchAndUpdateCardBrands()
        delegate?.didUpdate(element: self)
    }

    // MARK: Card brand choice
    private var cardBrands = Set<STPCardBrand>()
    func fetchAndUpdateCardBrands() {
        // Only fetch card brands if we have at least 8 digits in the pan
        guard let cardBrandDropDown = cardBrandDropDown, panElement.text.count >= 8 else {
            // Clear any previously fetched card brands from the dropdown
            self.cardBrands = Set<STPCardBrand>()
            cardBrandDropDown?.update(items: DropdownFieldElement.items(from: cardBrands, theme: self.theme))
            return
        }

        var fetchedCardBrands = Set<STPCardBrand>()
        STPCardValidator.possibleBrands(forNumber: panElement.text) { [weak self] result in
            switch result {
            case .success(let brands):
                cardBrandDropDown.validationState = .valid
                fetchedCardBrands = brands
            case .failure:
                cardBrandDropDown.validationState = .invalid(error: DropdownFieldElement.Error.failedToFetchBrands, shouldDisplay: true)
                fetchedCardBrands = Set<STPCardBrand>()
            }

            if self?.cardBrands != fetchedCardBrands {
                self?.cardBrands = fetchedCardBrands
                cardBrandDropDown.update(items: DropdownFieldElement.items(from: fetchedCardBrands, theme: self?.theme ?? .default))
                self?.panElement.setText(self?.panElement.text ?? "") // Hack to get the accessory view to update
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
