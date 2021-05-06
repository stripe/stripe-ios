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
        cvcImageView.image = STPImageLibrary.safeImageNamed(
            "card_cvc_icon", templateIfAvailable: false)  // TODO : This doesn't have special image for amex
        if cardBrand == .amex {
            placeholder = STPLocalizedString("CVV", "Label for entering CVV in text field")
        } else {
            placeholder = STPLocalizedString("CVC", "Label for entering CVC in text field")
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // Workaround until we can use image assets
        cvcImageView.image = STPImageLibrary.safeImageNamed(
            "card_cvc_icon", templateIfAvailable: false)  // TODO : This doesn't have special image for amex
    }
}
