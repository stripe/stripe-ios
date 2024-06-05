//
//  STPPostalCodeInputTextField.swift
//  StripePaymentsUI
//
//  Created by Cameron Sabol on 10/30/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@_spi(STP) public class STPPostalCodeInputTextField: STPInputTextField {

    var countryCode: String? = Locale.autoupdatingCurrent.stp_regionCode {
        didSet {
            updatePlaceholder()
            updateKeyboard()
            (formatter as! STPPostalCodeInputTextFieldFormatter).countryCode = countryCode
            (validator as! STPPostalCodeInputTextFieldValidator).countryCode = countryCode
            clearIfInvalid()
        }
    }

    public var postalCode: String? {
        return validator.inputValue
    }

    public convenience init(
        postalCodeRequirement: STPPostalCodeRequirement
    ) {
        self.init(
            formatter: STPPostalCodeInputTextFieldFormatter(),
            validator: STPPostalCodeInputTextFieldValidator(
                postalCodeRequirement: postalCodeRequirement
            )
        )
    }

    required init(
        formatter: STPInputTextFieldFormatter,
        validator: STPInputTextFieldValidator
    ) {
        assert(formatter.isKind(of: STPPostalCodeInputTextFieldFormatter.self))
        assert(validator.isKind(of: STPPostalCodeInputTextFieldValidator.self))
        super.init(formatter: formatter, validator: validator)
        updateKeyboard()
        textContentType = .postalCode
    }

    required init?(
        coder: NSCoder
    ) {
        super.init(coder: coder)
    }

    override func setupSubviews() {
        super.setupSubviews()
        accessibilityIdentifier = "Postal Code"
        updatePlaceholder()
    }

    private func updatePlaceholder() {
        guard STPPostalCodeValidator.postalCodeIsRequired(forCountryCode: countryCode) else {
            // don't update for countries that don't use postal codes (this helps with animations)
            return
        }
        if countryCode == "US" {
            placeholder = String.Localized.zip
        } else {
            placeholder = STPLocalizedString("Postal Code", "Postal code placeholder")
        }
        setNeedsLayout()
    }

    private func updateKeyboard() {
        if countryCode == "US" {
            keyboardType = .asciiCapableNumberPad
        } else {
            keyboardType = .numbersAndPunctuation
        }
    }

    private func clearIfInvalid() {
        if case .invalid = validator.validationState {
            self.text = ""
        }
    }
}
