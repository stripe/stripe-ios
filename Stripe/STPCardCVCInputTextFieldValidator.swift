//
//  STPCardCVCInputTextFieldValidator.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

class STPCardCVCInputTextFieldValidator: STPInputTextFieldValidator {
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
            validationState = .invalid(errorMessage: STPLocalizedString("Invalid CVC.", "Error message for card entry form when CVC/CVV is invalid"))
        case .incomplete:
            validationState = .incomplete(description: !inputValue.isEmpty ? STPLocalizedString("Incomplete CVC.", "Error message for card entry form when CVC/CVV is incomplete.") : nil)
        }
    }
}
