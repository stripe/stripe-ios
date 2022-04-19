//
//  STPCardNumberInputTextFieldValidator.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

class STPCardNumberInputTextFieldValidator: STPInputTextFieldValidator {    
    private var inputMode = STPCardNumberInputTextField.InputMode.standard
    
    override var defaultErrorMessage: String? {
        return STPLocalizedString(
            "Your card number is invalid.",
            "Error message for card form when card number is invalid")
    }

    private var overridenCardBrand: STPCardBrand?
    var cardBrand: STPCardBrand {
        if let overridenCardBrand = overridenCardBrand {
            return overridenCardBrand
        }
        guard let inputValue = inputValue,
            STPBINController.shared.hasBINRanges(forPrefix: inputValue)
        else {
            return .unknown
        }

        return STPCardValidator.brand(forNumber: inputValue)
    }

    override public var inputValue: String? {
        didSet {
            guard let inputValue = inputValue else {
                validationState = .incomplete(description: nil)
                return
            }
            let updateValidationState = {
                // Assume pan-locked is valid
                if self.inputMode == .panLocked {
                    self.validationState = .valid(message: nil)
                    return
                }
                
                switch STPCardValidator.validationState(
                    forNumber: inputValue, validatingCardBrand: true)
                {

                case .valid:
                    self.validationState = .valid(message: nil)
                case .invalid:
                    self.validationState = .invalid(errorMessage: self.defaultErrorMessage)
                case .incomplete:
                    self.validationState = .incomplete(
                        description: !inputValue.isEmpty
                            ? STPLocalizedString(
                                "Your card number is incomplete.",
                                "Error message for card form when card number is incomplete") : nil)
                }
            }
            if STPBINController.shared.hasBINRanges(forPrefix: inputValue) {
                updateValidationState()
            } else {
                STPBINController.shared.retrieveBINRanges(forPrefix: inputValue) { (result) in
                    // Needs better error handling and analytics https://jira.corp.stripe.com/browse/MOBILESDK-110
                    updateValidationState()
                }
                if STPBINController.shared.isLoadingCardMetadata(forPrefix: inputValue) {
                    validationState = .processing
                }
            }
        }
    }
    
    init(inputMode: STPCardNumberInputTextField.InputMode = .standard, cardBrand: STPCardBrand? = nil) {
        self.inputMode = inputMode
        self.overridenCardBrand = cardBrand
    }
}
