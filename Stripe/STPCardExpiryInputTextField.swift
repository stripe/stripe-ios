//
//  STPCardExpiryInputTextField.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

class STPCardExpiryInputTextField: STPInputTextField {

    public var expiryStrings: (month: String, year: String)? {
        return (validator as! STPCardExpiryInputTextFieldValidator).expiryStrings
    }

    public convenience init() {
        self.init(
            formatter: STPCardExpiryInputTextFieldFormatter(),
            validator: STPCardExpiryInputTextFieldValidator())
    }

    required init(formatter: STPInputTextFieldFormatter, validator: STPInputTextFieldValidator) {
        assert(formatter.isKind(of: STPCardExpiryInputTextFieldFormatter.self))
        assert(validator.isKind(of: STPCardExpiryInputTextFieldValidator.self))
        super.init(formatter: formatter, validator: validator)
        keyboardType = .asciiCapableNumberPad
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func setupSubviews() {
        super.setupSubviews()
        placeholder = STPLocalizedString("MM / YY", "label for text field to enter card expiry")
        accessibilityLabel = STPLocalizedString(
            "expiration date", "accessibility label for text field")
    }
}
