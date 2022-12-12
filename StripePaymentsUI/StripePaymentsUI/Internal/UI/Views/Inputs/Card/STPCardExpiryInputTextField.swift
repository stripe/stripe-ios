//
//  STPCardExpiryInputTextField.swift
//  StripePaymentsUI
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import UIKit

class STPCardExpiryInputTextField: STPInputTextField {

    public var expiryStrings: (month: String, year: String)? {
        return (validator as! STPCardExpiryInputTextFieldValidator).expiryStrings
    }

    public convenience init(
        prefillDetails: STPCardFormView.PrefillDetails? = nil
    ) {
        self.init(
            formatter: STPCardExpiryInputTextFieldFormatter(),
            validator: STPCardExpiryInputTextFieldValidator()
        )

        self.text = prefillDetails?.formattedExpiry  // pre-fill expiry if available
    }

    required init(
        formatter: STPInputTextFieldFormatter,
        validator: STPInputTextFieldValidator
    ) {
        assert(formatter.isKind(of: STPCardExpiryInputTextFieldFormatter.self))
        assert(validator.isKind(of: STPCardExpiryInputTextFieldValidator.self))
        super.init(formatter: formatter, validator: validator)
        keyboardType = .asciiCapableNumberPad
    }

    required init?(
        coder: NSCoder
    ) {
        super.init(coder: coder)
    }

    override func setupSubviews() {
        super.setupSubviews()
        accessibilityIdentifier = "expiration date"
        placeholder = String.Localized.mm_yy
        accessibilityLabel = String.Localized.expiration_date_accessibility_label
    }
}
