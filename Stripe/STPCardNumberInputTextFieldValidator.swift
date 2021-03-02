//
//  STPCardNumberInputTextFieldValidator.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

class STPCardNumberInputTextFieldValidator: STPInputTextFieldValidator {

    override var defaultErrorMessage: String? {
        return STPLocalizedString(
            "Your card number is invalid.",
            "Error message for card form when card number is invalid")
    }

    var cardBrand: STPCardBrand {
        guard let inputValue = inputValue,
            STPBINRange.hasBINRanges(forPrefix: inputValue)
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
            if STPBINRange.hasBINRanges(forPrefix: inputValue) {
                updateValidationState()
            } else {
                STPBINRange.retrieveBINRanges(forPrefix: inputValue) { (binRanges, error) in
                    // Needs better error handling and analytics https://jira.corp.stripe.com/browse/MOBILESDK-110
                    updateValidationState()
                }
                if STPBINRange.isLoadingCardMetadata(forPrefix: inputValue) {
                    validationState = .processing
                }
            }
        }
    }
}
