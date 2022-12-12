//
//  STPCardCVCInputTextFieldValidator.swift
//  StripePaymentsUI
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
import UIKit

class STPCardCVCInputTextFieldValidator: STPInputTextFieldValidator {

    override var defaultErrorMessage: String? {
        return STPLocalizedString(
            "Your card's security code is invalid.",
            "Error message for card entry form when CVC/CVV is invalid"
        )
    }

    var cardBrand: STPCardBrand = .unknown {
        didSet {
            checkInputValidity()
        }
    }

    override public var inputValue: String? {
        didSet {
            checkInputValidity()
        }
    }

    private func checkInputValidity() {
        guard let inputValue = inputValue else {
            validationState = .incomplete(description: nil)
            return
        }
        switch STPCardValidator.validationState(forCVC: inputValue, cardBrand: cardBrand) {
        case .valid:
            validationState = .valid(message: nil)
        case .invalid:
            validationState = .invalid(errorMessage: defaultErrorMessage)
        case .incomplete:
            validationState = .incomplete(
                description: !inputValue.isEmpty
                    ? String.Localized.your_cards_security_code_is_incomplete : nil
            )
        }
    }
}
