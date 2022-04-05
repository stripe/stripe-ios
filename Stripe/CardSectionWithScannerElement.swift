//
//  CardSectionWithScannerElement.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 3/24/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCore

/// A Element that contains a SectionElement for card details, whose view depends on the availability of card scanning:
/// If card scanning is available, it uses a custom view that adds card scanning. Otherwise, it uses the default SectionElement view.
/// It coordinates between the PAN and CVC fields.
final class CardSection: ContainerElement {
    var elements: [Element] {
        return [cardSection]
    }
    
    weak var delegate: ElementDelegate?
    lazy var view: UIView = {
        if #available(iOS 13.0, macCatalyst 14, *) {
            return CardSectionWithScannerView(cardSectionView: cardSection.view, delegate: self)
        } else {
            return cardSection.view
        }
    }()
    let cardSection: SectionElement
    
    // References to the underlying TextFieldElements
    let panElement: TextFieldElement
    let cvcElement: TextFieldElement
    let expiryElement: TextFieldElement
    
    init() {
        let panElement = PaymentMethodElementWrapper(TextFieldElement.PANConfiguration()) {  field, params in
            cardParams(for: params).number = field.text
            return params
        }
        let cvcElementConfiguration = TextFieldElement.CVCConfiguration() {
            return STPCardValidator.brand(forNumber: panElement.element.text)
        }
        let cvcElement = PaymentMethodElementWrapper(cvcElementConfiguration) { field, params in
            cardParams(for: params).cvc = field.text
            return params
        }
        let expiryElement = PaymentMethodElementWrapper(TextFieldElement.ExpiryDateConfiguration()) { field, params in
            if let month = Int(field.text.prefix(2)) {
                cardParams(for: params).expMonth = NSNumber(integerLiteral: month)
            }
            if let year = Int(field.text.suffix(2)) {
                cardParams(for: params).expYear = NSNumber(integerLiteral: year)
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
        self.cardSection = SectionElement(
            title: sectionTitle,
            elements: [
                panElement,
                SectionElement.MultiElementRow([expiryElement, cvcElement])
            ]
        )
        
        self.panElement = panElement.element
        self.cvcElement = cvcElement.element
        self.expiryElement = expiryElement.element
        cardSection.delegate = self
    }
    
    // MARK: - ElementDelegate
    private var cardBrand: STPCardBrand = .unknown
    func didUpdate(element: Element) {
        // Update the CVC field if the card brand changes
        let cardBrand = STPCardValidator.brand(forNumber: panElement.text)
        if self.cardBrand != cardBrand {
            self.cardBrand = cardBrand
            cvcElement.setText(cvcElement.text) // A hack to get the CVC to update
        }
        delegate?.didUpdate(element: self)
    }
}

// MARK: - Helpers
/// A DRY helper to ensure `STPPaymentMethodCardParams` is present on `intentConfirmParams.paymentMethodParams`.
fileprivate func cardParams(for intentParams: IntentConfirmParams) -> STPPaymentMethodCardParams {
    guard let cardParams = intentParams.paymentMethodParams.card else {
        let cardParams = STPPaymentMethodCardParams()
        intentParams.paymentMethodParams.card = cardParams
        return cardParams
    }
    return cardParams
}

// MARK: - CardSectionWithScannerViewDelegate

@available(iOS 13, macCatalyst 14, *)
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
