//
//  STPCardCVCInputTextField.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

class STPCardCVCInputTextField: STPInputTextField {

    public var cardBrand: STPCardBrand = .unknown {
        didSet {
            cvcFormatter.cardBrand = cardBrand
            cvcValidator.cardBrand = cardBrand
            updateCVCImageAndPlaceholder()
            truncateTextIfNeeded()
        }
    }

    var cvcFormatter: STPCardCVCInputTextFieldFormatter {
        return formatter as! STPCardCVCInputTextFieldFormatter
    }

    var cvcValidator: STPCardCVCInputTextFieldValidator {
        return validator as! STPCardCVCInputTextFieldValidator
    }

    let cvcHintView = CardBrandView(showCVC: true)

    public convenience init() {
        self.init(
            formatter: STPCardCVCInputTextFieldFormatter(),
            validator: STPCardCVCInputTextFieldValidator())
    }

    required init(formatter: STPInputTextFieldFormatter, validator: STPInputTextFieldValidator) {
        assert(formatter.isKind(of: STPCardCVCInputTextFieldFormatter.self))
        assert(validator.isKind(of: STPCardCVCInputTextFieldValidator.self))
        super.init(formatter: formatter, validator: validator)
        keyboardType = .asciiCapableNumberPad
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func setupSubviews() {
        super.setupSubviews()
        accessibilityIdentifier = "CVC"
        addAccessoryViews([cvcHintView])
        updateCVCImageAndPlaceholder()
    }

    func updateCVCImageAndPlaceholder() {
        cvcHintView.setCardBrand(cardBrand, animated: true)

        if cardBrand == .amex {
            placeholder = STPLocalizedString("CVV", "Label for entering CVV in text field")
        } else {
            placeholder = STPLocalizedString("CVC", "Label for entering CVC in text field")
        }
    }

    func truncateTextIfNeeded() {
        guard let text = self.text else {
            return
        }

        let maxLength = Int(STPCardValidator.maxCVCLength(for: cardBrand))
        if text.count > maxLength {
            self.text = text.stp_safeSubstring(to: maxLength)
        }
    }
}
