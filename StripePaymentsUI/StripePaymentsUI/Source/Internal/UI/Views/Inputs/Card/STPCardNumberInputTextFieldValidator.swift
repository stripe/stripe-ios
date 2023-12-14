//
//  STPCardNumberInputTextFieldValidator.swift
//  StripePaymentsUI
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
import UIKit

class STPCardNumberInputTextFieldValidator: STPInputTextFieldValidator {
    private var inputMode = STPCardNumberInputTextField.InputMode.standard

    override var defaultErrorMessage: String? {
        return String.Localized.your_card_number_is_invalid
    }

    private var overridenCardBrand: STPCardBrand?
    var cardBrandState: STPCBCController.BrandState {
        if let overridenCardBrand = overridenCardBrand {
            return .brand(overridenCardBrand)
        }

        if cbcController.cbcEnabled {
            return cbcController.brandState
        }

        guard let inputValue = inputValue,
            STPBINController.shared.hasBINRanges(forPrefix: inputValue)
        else {
            return .unknown
        }

        return .brand(STPCardValidator.brand(forNumber: inputValue))
    }

    override public var inputValue: String? {
        didSet {
            cbcController.cardNumber = inputValue
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
                    forNumber: inputValue,
                    validatingCardBrand: true
                )
                {

                case .valid:
                    self.validationState = .valid(message: nil)
                case .invalid:
                    self.validationState = .invalid(errorMessage: self.defaultErrorMessage)
                case .incomplete:
                    self.validationState = .incomplete(
                        description: !inputValue.isEmpty
                            ? String.Localized.your_card_number_is_incomplete : nil
                    )
                }
            }
            if STPBINController.shared.hasBINRanges(forPrefix: inputValue) {
                updateValidationState()
            } else {
                STPBINController.shared.retrieveBINRanges(forPrefix: inputValue) { (_) in
                    // Needs better error handling and analytics https://jira.corp.stripe.com/browse/MOBILESDK-110
                    updateValidationState()
                }
                if STPBINController.shared.isLoadingCardMetadata(forPrefix: inputValue) {
                    validationState = .processing
                }
            }
        }
    }

    let cbcController = STPCBCController()

    init(
        inputMode: STPCardNumberInputTextField.InputMode = .standard,
        cardBrand: STPCardBrand? = nil,
        cbcEnabledOverride: Bool? = nil
    ) {
        self.inputMode = inputMode
        self.overridenCardBrand = cardBrand
        self.cbcController.cbcEnabledOverride = cbcEnabledOverride
    }
}
