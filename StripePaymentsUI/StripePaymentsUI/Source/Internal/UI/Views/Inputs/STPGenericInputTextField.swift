//
//  STPGenericInputTextField.swift
//  StripePaymentsUI
//
//  Created by Cameron Sabol on 11/19/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

class STPGenericInputTextField: STPInputTextField {

    class Validator: STPInputTextFieldValidator {
        var optional: Bool = false {
            didSet {
                updateValidationState()
            }
        }

        override var inputValue: String? {
            didSet {
                updateValidationState()
            }
        }

        func updateValidationState() {
            validationState =
                (inputValue?.count ?? 0 > 0 || optional)
                ? .valid(message: nil) : .incomplete(description: nil)
        }
    }

    public convenience init(
        placeholder: String,
        textContentType: UITextContentType? = nil,
        keyboardType: UIKeyboardType = .default,
        optional: Bool = false
    ) {
        let validator = STPGenericInputTextField.Validator()
        validator.optional = optional
        self.init(formatter: STPInputTextFieldFormatter(), validator: validator)
        self.placeholder = placeholder
        self.textContentType = textContentType
        self.keyboardType = keyboardType
    }

    required init(
        formatter: STPInputTextFieldFormatter,
        validator: STPInputTextFieldValidator
    ) {
        assert(formatter.isKind(of: STPInputTextFieldFormatter.self))
        assert(validator.isKind(of: STPGenericInputTextField.Validator.self))
        super.init(formatter: formatter, validator: validator)
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

}
