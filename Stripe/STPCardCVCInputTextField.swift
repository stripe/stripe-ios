//
//  STPCardCVCInputTextField.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

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

    let cvcImageView = UIImageView()

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
        addAccessoryImageViews([cvcImageView])
        updateCVCImageAndPlaceholder()
    }

    func updateCVCImageAndPlaceholder() {
        if cardBrand == .amex {
            placeholder = STPLocalizedString("CVV", "Label for entering CVV in text field")
            cvcImageView.image = STPImageLibrary.safeImageNamed(
                "card_cvc_amex_icon", templateIfAvailable: false)
        } else {
            placeholder = STPLocalizedString("CVC", "Label for entering CVC in text field")
            cvcImageView.image = STPImageLibrary.safeImageNamed(
                "card_cvc_icon", templateIfAvailable: false)
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateCVCImageAndPlaceholder()
    }
}
