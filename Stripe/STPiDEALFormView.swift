//
//  STPiDEALFormView.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 2/4/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

final class STPiDEALFormView: STPFormView {

    private let bankField: STPiDEALBankPickerInputField

    var iDEALParams: STPPaymentMethodParams? {
        get {
            guard case .valid = bankField.validator.validationState,
                let bankName = bankField.inputValue
            else {
                return nil
            }

            let idealParams = STPPaymentMethodiDEALParams()
            idealParams.bankName = bankName

            // TODO(mludowise|MOBILESDK-161): Add billing details
            return STPPaymentMethodParams(
                iDEAL: idealParams,
                billingDetails: nil,
                metadata: nil)
        }
        set {
            if let bankID = newValue?.iDEAL?.bankName {
                bankField.text = bankID
            }
        }
    }

    /*
     TODO(mludowise|MOBILESDK-161): Add `PaymentSheet.BillingAddressCollectionLevel`
     as a parameter on init to include billing. iDEAL should require a minimum of
     the account holder's name for automatic BillingAddressCollectionLevel.

     This would require refactoring of `STPCardFormView.BillingAddressSubForm`
     so we could reuse it for other payment methods.
     */
    convenience init() {
        self.init(bankField: STPiDEALBankPickerInputField())
    }

    init(bankField: STPiDEALBankPickerInputField) {
        self.bankField = bankField

        let bankSection = STPFormView.Section(
            rows: [[bankField]],
            title: STPLocalizedString(
                "iDEAL Bank", "iDEAL bank section title for iDEAL form entry."),
            accessoryButton: nil
        )
        super.init(sections: [bankSection])
        bankField.addObserver(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(sections: [Section]) {
        fatalError("init(sections:) has not been implemented")
    }

    override func validationDidUpdate(
        to state: STPValidatedInputState, from previousState: STPValidatedInputState,
        for unformattedInput: String?, in input: STPFormInput
    ) {
        guard let field = input as? STPInputTextField,
            field === bankField
        else {
            return
        }

        if case .valid = state, state != previousState {
            internalDelegate?.formView(self, didChangeToStateComplete: true)
        } else if case .valid = previousState, state != previousState {
            internalDelegate?.formView(self, didChangeToStateComplete: true)
        }
    }

    /// Returns true iff the form can mark the error to one of its fields
    func markFormErrors(for apiError: Error) -> Bool {
        // TODO(mludowise|MOBILESDK-161): Handle error codes related to billing
        // when that's been added
        return false
    }
}
